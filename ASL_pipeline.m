function ASL_pipeline(path_code, cfgfn_subj)
% ASL processing pipeline
% yli20161118

%% Load ASL parameters
asl_paras   = loadjson(cfgfn_subj);
asl_paras   = ASL_sortVols(asl_paras); % sort out volumes if asl/diff and m0 are combined

path_data    = asl_paras.DIRECTORY.path_data;
path_output  = asl_paras.DIRECTORY.path_output;
name_asl     = asl_paras.SINGLPROC.name_asl;
flag_m0      = asl_paras.SINGLPROC.flag_m0;
name_m0      = asl_paras.SINGLPROC.name_m0;
flag_t1      = asl_paras.SINGLPROC.flag_t1;
name_t1      = asl_paras.SINGLPROC.name_t1;

asl_paras.SINGLPROC.path_temp             = [path_data filesep 'temp_' name_asl];
asl_paras.SINGLPROC.path_output_subj      = [path_output filesep 'ASLMRICloud_Output_' name_asl];
asl_paras.SINGLPROC.path_output_subj_rslt = [asl_paras.SINGLPROC.path_output_subj filesep 'results'];
asl_paras.SINGLPROC.path_output_subj_rdat = [asl_paras.SINGLPROC.path_output_subj filesep 'dataset'];
path_temp                       = asl_paras.SINGLPROC.path_temp; % directory to hold intermediate outputs
path_output_subj                = asl_paras.SINGLPROC.path_output_subj; % directory to hold two folders
path_output_subj_rslt           = asl_paras.SINGLPROC.path_output_subj_rslt; % directory to hold results
path_output_subj_rdat           = asl_paras.SINGLPROC.path_output_subj_rdat; % directory to hold raw data

flag_multidelay                 = asl_paras.BASICPARA.flag_multidelay;

% if ~isfield(asl_paras.OTHERPARA,'findabnorm') % check if find abnormal region
%     asl_paras.OTHERPARA.findabnorm = 1; % find abnormal region by default
% end
% if ~isfield(asl_paras.OTHERPARA,'applyBrnMsk') % check if apply brainmask
%     asl_paras.OTHERPARA.applyBrnMsk = 1; % apply mask by default
% end
% if ~isfield(asl_paras.OTHERPARA,'useGloM0in3D') % check if use M0_glo when 3D
%     asl_paras.OTHERPARA.useGloM0in3D = 0; % not use GlodM0 in 3D by default
% end

disp(['ASLMRICloud: (' name_asl ') Load parameters...']);


%% ASL analysis in native space 
% creat new folders for processing (path_temp) and output (path_output_subj_rslt)
if exist(path_temp,'dir')
    rmdir(path_temp,'s');
end
if exist(path_output_subj,'dir')
    rmdir(path_output_subj,'s');
end
mkdir(path_temp);
mkdir(path_output_subj_rslt);

% print parameters into a text file
ASL_printParas(asl_paras);

% scale data using scaling factor
if flag_m0
    ASL_rescale(path_data,path_temp,name_asl);
    ASL_rescale(path_data,path_temp,name_m0);
else
    ASL_rescale(path_data,path_temp,name_asl);
end

if flag_multidelay == 0 % single-delay
    % perform motion correction
    ASL_realign(path_temp,name_asl);
    
    % outlier rejection
    % ASL_rejectOutlier();
    
    % calculate ASL diff image
    ASL_calculateDiffMap(path_temp,asl_paras);
    
    % calculate M0
    ASL_calculateM0(path_temp,path_code,asl_paras);
    
    % quantify absolute/relative CBF and copy to output folder
    ASL_calculateCBFmap(path_temp,asl_paras);
    
    copyfile([path_temp filesep 'rp_' name_asl '.txt'],[path_output_subj_rslt filesep 'motion_vectors.txt']);
    copyfile([path_temp filesep 'r' name_asl '_aCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_aCBF_native.hdr']);
    copyfile([path_temp filesep 'r' name_asl '_aCBF_native.img'],[path_output_subj_rslt filesep name_asl '_aCBF_native.img']);
    copyfile([path_temp filesep 'r' name_asl '_rCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_rCBF_native.hdr']);
    copyfile([path_temp filesep 'r' name_asl '_rCBF_native.img'],[path_output_subj_rslt filesep name_asl '_rCBF_native.img']);
    
    % rate the general quality of ASL image
    ASL_rateImgQuality(path_temp,asl_paras);
    
elseif flag_multidelay == 1 % multi-delay
    % TODO: multidelay motion correction
    % realign each pld, then coregister to 1st pld
    % ASL_multiDelay_realign(path_temp,name_asl);
    
    % calculate ASL diff image
    ASL_calculateDiffMap(path_temp,asl_paras);
    
    % calculate M0
    ASL_multiDelay_calculateM0(path_temp,path_code,asl_paras);
    
    % quantify absolute/relative CBF and copy to output folder
    ASL_multiDelay_calculateCBFATT(path_temp,asl_paras);
    
    copyfile([path_temp filesep 'r' name_asl '_aCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_aCBF_native.hdr']);
    copyfile([path_temp filesep 'r' name_asl '_aCBF_native.img'],[path_output_subj_rslt filesep name_asl '_aCBF_native.img']);
    copyfile([path_temp filesep 'r' name_asl '_rCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_rCBF_native.hdr']);
    copyfile([path_temp filesep 'r' name_asl '_rCBF_native.img'],[path_output_subj_rslt filesep name_asl '_rCBF_native.img']);
    copyfile([path_temp filesep 'r' name_asl  '_ATT_native.hdr'],[path_output_subj_rslt filesep name_asl  '_ATT_native.hdr']);
    copyfile([path_temp filesep 'r' name_asl  '_ATT_native.img'],[path_output_subj_rslt filesep name_asl  '_ATT_native.img']);
end


%% ROI analysis using T1-based parcellation after performing T1-multiatlas
if flag_t1 % if MPRAGE zipfolder is uploaded
    
    % unzip t1-multialtas result
    unzip([path_data filesep name_t1 '.zip'],[path_data filesep name_t1]);

    % Get mprage name
    alllist = dir([path_data,filesep,name_t1]); % find the folder name inside the unzipped directory
    fdrlist = {alllist.name};
    mydir   = vertcat(alllist.isdir);
    fdrlist = fdrlist(mydir);
    fdrlist = fdrlist{end};
    path_mpr    = [path_data,filesep,name_t1,filesep,fdrlist];
    name_tmp    = spm_select('List',path_mpr,'.*[^mni].imgsize$');
    name_mpr    = name_tmp(1:end-8);
        
    % coregister CBF map to Skull-stripped MPRAGE
    disp(['ASLMRICloud: (' name_asl ') Coregister CBF maps to MPRAGE...']);
    mpr_brain = ASL_mprageSkullstrip(path_mpr, name_mpr);
    target = mpr_brain;
    if flag_m0 % use source with high snr (m0 > ctrl)
        source = [path_temp filesep 'r' name_asl '_m0ave.img'];
    else
        source = [path_temp filesep 'mean' name_asl '.img'];
    end
    other1 = [path_temp filesep 'r' name_asl '_aCBF_native.img'];
    other2 = [path_temp filesep 'r' name_asl '_rCBF_native.img'];
    other3 = [path_temp filesep 'r' name_asl '_brnmsk_clcu.img'];
    other4 = [path_temp filesep 'r' name_asl '_ATT_native.img'];
    if flag_multidelay == 0 % single-delay
        ASL_coreg(target,source,other1,other2,other3);
    else % multi-delay
    	ASL_coreg(target,source,other1,other2,other3,other4);
    end

    % copy CBF in mpr space to output folder
    copyfile([path_temp filesep 'rr' name_asl '_aCBF_native.img'],[path_output_subj_rslt filesep name_asl '_aCBF_mpr.img']);
    copyfile([path_temp filesep 'rr' name_asl '_aCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_aCBF_mpr.hdr']);
    copyfile([path_temp filesep 'rr' name_asl '_rCBF_native.img'],[path_output_subj_rslt filesep name_asl '_rCBF_mpr.img']);
    copyfile([path_temp filesep 'rr' name_asl '_rCBF_native.hdr'],[path_output_subj_rslt filesep name_asl '_rCBF_mpr.hdr']);
    if exist([path_temp filesep 'rr' name_asl '_ATT_native.img'],'file') % case of multi-delay
        copyfile([path_temp filesep 'rr' name_asl '_ATT_native.img'],[path_output_subj_rslt filesep name_asl '_ATT_mpr.img']);
        copyfile([path_temp filesep 'rr' name_asl '_ATT_native.hdr'],[path_output_subj_rslt filesep name_asl '_ATT_mpr.hdr']);
    end
    
    % ROI analysis in native space
    disp(['ASLMRICloud: (' name_asl ') Perform ROI analysis...']);
    outcbf_mpr  = {[path_output_subj_rslt filesep name_asl '_aCBF_mpr.img'];
                   [path_output_subj_rslt filesep name_asl '_rCBF_mpr.img'];
                   [path_output_subj_rslt filesep name_asl '_ATT_mpr.img']};
    acbffile    = outcbf_mpr{1};
    rcbffile    = outcbf_mpr{2};
    attfile     = outcbf_mpr{3}; % TODO: add att roi reports.
    rmskfile    = [path_temp filesep 'rr' name_asl '_brnmsk_clcu.img'];
    ASL_T1ROI_CBFaverage(path_mpr,name_mpr,acbffile,rcbffile,rmskfile,path_output_subj_rslt);
    
    % Normalize CBF/ATT map to MNI space
    disp(['ASLMRICloud: (' name_asl ') Normalize CBF maps to MNI space...']);
    tmpcbf_mni = {[path_temp filesep name_asl '_aCBF_MNI.img'];
                  [path_temp filesep name_asl '_rCBF_MNI.img'];
                  [path_temp filesep name_asl '_ATT_MNI.img']};
    outcbf_mni = {[path_output_subj_rslt filesep name_asl '_aCBF_MNI.img'];
                  [path_output_subj_rslt filesep name_asl '_rCBF_MNI.img'];
                  [path_output_subj_rslt filesep name_asl '_ATT_MNI.img']};
              
    nummaps = 2*(flag_multidelay == 0) + 3*(flag_multidelay == 1); % single/multi-delay
    for ii = 1:nummaps
        cmd1 = [path_code filesep 'IMG_apply_AIR_tform1 ' ...
            outcbf_mpr{ii} ' ' tmpcbf_mni{ii} ' ' ...
            path_mpr filesep 'matrix_air.txt 1 ' ...
            path_mpr filesep 'mni.imgsize 1'];
        cmd2 = [path_code filesep 'IMG_change_res_info ' ...
            tmpcbf_mni{ii} ' ' tmpcbf_mni{ii} ' 1 1 1'];
        
        system(cmd1);
        system(cmd2);
        ASL_downSampleMNI(tmpcbf_mni{ii},outcbf_mni{ii});
    end

    % detect the abnormal CBF region
    disp(['ASLMRICloud: (' name_asl ') Detect abnormal CBF regions...']);
    if asl_paras.OTHERPARA.findabnorm
        rcbftpm_ave_s12 = [path_code filesep 'tpm' filesep 'rCBF_291control_MNI_s12mm_ave.img'];
        rcbftpm_std_s12 = [path_code filesep 'tpm' filesep 'rCBF_291control_MNI_s12mm_std.img'];
        rcbftpm_mask    = [path_code filesep 'tpm' filesep 'rCBF_291control_MNI_brainmask.img'];
        rcbfmni         = [path_output_subj_rslt filesep name_asl '_rCBF_MNI.img'];
        msk0mni         = ASL_getMNImask(path_mpr, name_mpr);
        maskmni         = [path_temp filesep name_mpr '_mnimask222.img'];
        ASL_downSampleMNI(msk0mni,maskmni);
        ASL_findAbnormalCBF(rcbfmni,maskmni,rcbftpm_ave_s12,rcbftpm_std_s12,rcbftpm_mask,path_output_subj_rslt);
    end

end

%% orgnize output files & uploaded data for zip
copyfile([path_data filesep name_asl '.*'], path_output_subj_rdat);
if flag_m0
    copyfile([path_data filesep name_m0 '.*'], path_output_subj_rdat);
end
if flag_t1
    copyfile([path_data filesep name_t1 '.zip'],path_output_subj_rdat);
end

