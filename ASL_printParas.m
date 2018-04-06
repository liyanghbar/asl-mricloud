function ASL_printParas(asl_paras)
% Print all the parameters in the txt file, which can help user to track
% their inputs.

flag_m0                 = asl_paras.SINGLPROC.flag_m0;

% flag_pCASLuclaSiemens   = asl_paras.BASICPARA.flag_pCASLuclaSiemens;
labl_schm               = asl_paras.BASICPARA.labl_schm;
% labl_ordr               = asl_paras.BASICPARA.labl_ordr;
scan_mode               = asl_paras.BASICPARA.scan_mode;
casl_dur                = asl_paras.BASICPARA.casl_dur;
casl_pld                = asl_paras.BASICPARA.casl_pld;
pasl_ti1                = asl_paras.BASICPARA.pasl_ti1;
pasl_ti                 = asl_paras.BASICPARA.pasl_ti;
slic_dur                = asl_paras.BASICPARA.slic_dur;

flag_bgs                = asl_paras.BGSUPPRES.flag_bgs;
bgsu_time               = asl_paras.BGSUPPRES.bgsu_time;
bgsu_num                = asl_paras.BGSUPPRES.bgsu_num;
bgsu_eff                = asl_paras.BGSUPPRES.bgsu_eff;

m0_tr                   = asl_paras.M0QUANEST.m0_tr;	
t1_tissue               = asl_paras.M0QUANEST.t1_tissue;

t1_blood                = asl_paras.CBFQUANTI.t1_blood;
part_coef               = asl_paras.CBFQUANTI.part_coef;
labl_eff                = asl_paras.CBFQUANTI.labl_eff;

asl_paras_print = {
    '===================ASL PIPELINE PARAMETERS===================', [' ']; % 1
    'Labeling scheme                        : ', []; % 2
%     'Control/label order                    : ', []; % 3
    'Acquisition scheme                     : ', []; % 4
    'Labeling duration [ms]                 : ', []; % 5
    'Post-labeling delay [ms]               : ', []; % 6
    'TI1 time [ms]                          : ', []; % 7
    'TI time [ms]                           : ', []; % 8
    'Slice acquisition duration [ms]        : ', []; % 9
    'Background suppression [Yes/No]        : ', []; % 10
    'Back. supp. pulse time [ms]            : ', []; % 11
    'Num. of inv. pulses after labeling     : ', []; % 12
    'Inversion efficiency                   : ', []; % 13
    'TR of M0 scan [ms]                     : ', []; % 14
    'Tissue T1 [ms]                         : ', []; % 15
    'Blood T1 [ms]                          : ', []; % 16
    'Brain/blood partition coeff. [ml/g]    : ', []; % 17
    'Labeling efficiency                    : ', [] }; % 18

asl_paras_print{2,2} = labl_schm;
% if strcmp(labl_schm,'pCASL') && (flag_pCASLuclaSiemens)
%     asl_paras_print{2,2} = 'UCLA_Siemens_pCASL';
% end
% asl_paras_print{3,2} = labl_ordr;
asl_paras_print{3,2} = scan_mode;

if strcmp(labl_schm,'pCASL')
    asl_paras_print{4,2} = num2str(casl_dur);
    asl_paras_print{5,2} = num2str(casl_pld);
elseif strcmp(labl_schm,'PASL')
    asl_paras_print{6,2} = num2str(pasl_ti1);
    asl_paras_print{7,2} = num2str(pasl_ti);
end

if strcmp(scan_mode,'2D')
    asl_paras_print{8,2} = num2str(slic_dur);
end

if flag_bgs
    asl_paras_print{9,2} = 'Y';
    if flag_m0 == 0
        asl_paras_print{10,2} = num2str(bgsu_time);
    end
    asl_paras_print{11,2} = num2str(bgsu_num);
    asl_paras_print{12,2} = num2str(bgsu_eff);
else
    asl_paras_print{9,2} = 'N';
end

if flag_m0 == 1
    asl_paras_print{13,2} = num2str(m0_tr);
end

if (m0_tr < 5000) || (flag_m0 == 0)
    asl_paras_print{14,2} = num2str(t1_tissue);
end

asl_paras_print{15,2} = num2str(t1_blood);
asl_paras_print{16,2} = num2str(part_coef);
asl_paras_print{17,2} = num2str(labl_eff);

% write paras into text file
fileID = fopen([asl_paras.SINGLPROC.path_output_subj_rslt filesep 'asl_info.txt'],'w');
formatSpec = '%s %s\n';
for row = 1:length(asl_paras_print)
    if ~isempty(asl_paras_print{row,2})
        fprintf(fileID,formatSpec,asl_paras_print{row,:});
    end
end
fclose(fileID);

% write paras into .json for future uploading
asl_paras_json = asl_paras;
asl_paras_json = rmfield(asl_paras_json,'DIRECTORY');
asl_paras_json = rmfield(asl_paras_json,'SINGLPROC');

asl_paras_jsonname = 'asl_paras_for_future_uploading.json';
savejson('',asl_paras_json,[asl_paras.SINGLPROC.path_output_subj_rslt filesep asl_paras_jsonname]);

