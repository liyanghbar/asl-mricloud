function ASL_printParas(asl_paras)
% Print all the parameters in the txt file, which can help user to track
% their inputs.
asl_paras_print = {
    '===================ASL PIPELINE PARAMETERS=================== ', []; % 1
    'Labeling scheme                        : ', []; % 2
    'Control/label order                    : ', []; % 3
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

asl_paras_print{2,2} = asl_paras.lablschm;
if strcmp(asl_paras.lablschm,'pCASL') && (asl_paras.UCLA_Siemens_pCASL)
    asl_paras_print{2,2} = 'UCLA_Siemens_pCASL';
end
asl_paras_print{3,2} = asl_paras.order;
asl_paras_print{4,2} = asl_paras.acqdim;

if strcmp(asl_paras.lablschm,'pCASL')
    asl_paras_print{5,2} = num2str(asl_paras.labldur);
    asl_paras_print{6,2} = num2str(asl_paras.PLD);
elseif strcmp(asl_paras.lablschm,'PASL')
    asl_paras_print{7,2} = num2str(asl_paras.TI1);
    asl_paras_print{8,2} = num2str(asl_paras.TI);
end

if strcmp(asl_paras.acqdim,'2D')
    asl_paras_print{9,2} = num2str(asl_paras.w);
end

if asl_paras.bgsup == 1
    asl_paras_print{10,2} = 'Y';
    if asl_paras.M0data == 0
        asl_paras_print{11,2} = num2str(asl_paras.time_BS);
    end
    asl_paras_print{12,2} = num2str(asl_paras.num_BS);
    asl_paras_print{13,2} = num2str(asl_paras.alpha_BS);
elseif asl_paras.bgsup == 0
    asl_paras_print{10,2} = 'N';
end

if asl_paras.M0data == 1
    asl_paras_print{14,2} = num2str(asl_paras.M0_TR);
end

if (asl_paras.M0_TR < 5000) || (asl_paras.M0data == 0)
    asl_paras_print{15,2} = num2str(asl_paras.T1tissue);
end

asl_paras_print{16,2} = num2str(asl_paras.T1blood);
asl_paras_print{17,2} = num2str(asl_paras.lambda);
asl_paras_print{18,2} = num2str(asl_paras.alpha_labl);

% write paras into text file
fileID = fopen([asl_paras.outpath filesep 'asl_paras.txt'],'w');
% fileID = fopen(['asl_paras.txt'],'w');
formatSpec = '%s %s\n';
fprintf(fileID,formatSpec,asl_paras_print{1,:});
for row = 2:length(asl_paras_print)
    if ~isempty(asl_paras_print{row,2})
        fprintf(fileID,formatSpec,asl_paras_print{row,:});
    end
end
fclose(fileID);

% write paras into .json for future uploading
asl_paras_json = asl_paras;
asl_paras_json = rmfield(asl_paras_json,'datapath');
asl_paras_json = rmfield(asl_paras_json,'outpath');
asl_paras_json = rmfield(asl_paras_json,'aslname');
asl_paras_json = rmfield(asl_paras_json,'M0data');
asl_paras_json = rmfield(asl_paras_json,'M0name');
asl_paras_json = rmfield(asl_paras_json,'MPRdata');
asl_paras_json = rmfield(asl_paras_json,'mprpath');

asl_paras_jsonname = 'asl_paras_for_future_uploading.json';
savejson('',asl_paras_json,[asl_paras.outpath filesep asl_paras_jsonname]);

