function ASL_pipeline(scriptpath, cfgfn)
% ASL processing pipeline
% yli20160101

%% Load ASL parameters
asl_paras   = loadjson(cfgfn);

% split M0 and ASL scan if the protocol is 'UCLA Siemens pCASL'
if (asl_paras.UCLA_Siemens_pCASL)
    P = spm_select('FPList',asl_paras.datapath,[asl_paras.aslname '.*img']);
    V = spm_vol(P);
    volall = spm_read_vols(V);
    
    outVol          = V(1);
    outVol          = rmfield(outVol,'private');
    outVol.mat      = V(1).mat;
    outVol.descrip  = 'm0 images';
    outVol.fname    = [asl_paras.datapath filesep asl_paras.aslname '_m0.img'];
    spm_write_vol(outVol,volall(:,:,:,1));

    for ii = 3:length(V)
        outVol          = V(ii);
        outVol          = rmfield(outVol,'private');
        outVol.descrip  = 'asl images';
        outVol.n        = [ii-2,1];
        outVol.fname = [asl_paras.datapath filesep asl_paras.aslname '_asl.img'];
        spm_write_vol(outVol,volall(:,:,:,ii));
    end

    % overwrite some asl_paras
    dataname              = asl_paras.aslname;
    asl_paras.aslname     = [dataname '_asl'];
    asl_paras.M0name      = [dataname '_m0'];
end

datapath    = asl_paras.datapath;
outpath     = asl_paras.outpath;
aslname     = asl_paras.aslname;
M0data      = asl_paras.M0data;
M0name      = asl_paras.M0name;
MPRdata     = asl_paras.MPRdata;
mprpath     = asl_paras.mprpath;

asl_paras.dirrslt = [outpath filesep 'results'];
asl_paras.dirrdat = [outpath filesep 'dataset'];
dirrslt     = asl_paras.dirrslt; % directory to hold results
dirrdat     = asl_paras.dirrdat; % directory to hold raw data

if ~isfield(asl_paras,'findabnorm') % check if find abnormal region
    asl_paras.findabnorm = 1; % find abnormal region by default
end
findabnorm  = asl_paras.findabnorm;

if ~isfield(asl_paras,'applyBrnMsk') % check if apply brainmask
    asl_paras.applyBrnMsk = 1; % apply mask by default
end
if ~isfield(asl_paras,'useGloM0in3D') % check if use M0_glo when 3D
    asl_paras.useGloM0in3D = 0; % not use GlodM0 in 3D by default
end


%% ASL analysis in native space 
% creat new folders for processing ("tmp") and output ("output")
tmppath = [datapath filesep 'tmp'];
if exist(tmppath,'dir')
    rmdir(tmppath,'s');
end
if exist(dirrslt,'dir')
    rmdir(dirrslt,'s');
end
mkdir(tmppath);
mkdir(dirrslt);

% print parameters into a text file
ASL_printParas(asl_paras);

% scale data using scaling factor
ASL_rescale(datapath,tmppath,aslname);
if M0data == 1
    ASL_rescale(datapath,tmppath,M0name);
end

% perform motion correction
ASL_realign(tmppath,aslname);
copyfile([tmppath filesep 'rp_' aslname '.txt'], ...
         [dirrslt filesep aslname '_motion_vectors.txt']);

% % outlier rejection
% ASL_rejectOutlier();

% calculate ASL diff image
diff = ASL_calculateDiffMap(tmppath,asl_paras);

% calculate M0
imgtpm = [scriptpath filesep 'tpm' filesep 'TPM.nii'];
target = [tmppath filesep 'mean' aslname '.img'];
[M0map,brnmsk_dspl,brnmsk_clcu] = ASL_calculateM0(tmppath,target,imgtpm,asl_paras);

% quantify absolute/relative CBF and copy to output folder
ASL_calculateCBFmap(tmppath,diff,M0map,brnmsk_dspl,brnmsk_clcu,asl_paras);

copyfile([tmppath filesep 'r' aslname '_aCBF_thre_native.hdr'],[dirrslt filesep aslname '_aCBF_thre_native.hdr']);
copyfile([tmppath filesep 'r' aslname '_aCBF_thre_native.img'],[dirrslt filesep aslname '_aCBF_thre_native.img']);
copyfile([tmppath filesep 'r' aslname '_rCBF_thre_native.hdr'],[dirrslt filesep aslname '_rCBF_thre_native.hdr']);
copyfile([tmppath filesep 'r' aslname '_rCBF_thre_native.img'],[dirrslt filesep aslname '_rCBF_thre_native.img']);

% rate the general quality of ASL image
ASL_rateImgQuality(tmppath,asl_paras);


%% ROI analysis using T1-based parcellation after performing T1-multiatlas
if ~isempty(mprpath) % if MPRAGE zipfolder is uploaded
    
    % Get mprage name
    tmpname  = spm_select('List',mprpath,'.*[^mni].imgsize$');
    mprname  = tmpname(1:end-8);
        
    % coregister CBF map to Skull-stripped MPRAGE
    mpr_brain = ASL_mprageSkullstrip(mprpath, mprname);
    target = mpr_brain;
    source = [tmppath filesep 'mean' aslname '.img'];
    other  = [tmppath filesep 'r' aslname '_aCBF_thre_native.img';
              tmppath filesep 'r' aslname '_rCBF_thre_native.img'];
    ASL_coregister(target,source,other);

    % copy CBF in mpr space to output folder
    copyfile([tmppath filesep 'rr' aslname '_aCBF_thre_native.img'],[dirrslt filesep aslname '_aCBF_thre_mpr.img']);
    copyfile([tmppath filesep 'rr' aslname '_aCBF_thre_native.hdr'],[dirrslt filesep aslname '_aCBF_thre_mpr.hdr']);
    copyfile([tmppath filesep 'rr' aslname '_rCBF_thre_native.img'],[dirrslt filesep aslname '_rCBF_thre_mpr.img']);
    copyfile([tmppath filesep 'rr' aslname '_rCBF_thre_native.hdr'],[dirrslt filesep aslname '_rCBF_thre_mpr.hdr']);
    
    % ROI analysis in native space
    outcbf_mpr  = [[dirrslt filesep aslname '_aCBF_thre_mpr.img'];
                   [dirrslt filesep aslname '_rCBF_thre_mpr.img']];
    acbffile    = outcbf_mpr(1,:);
    rcbffile    = outcbf_mpr(2,:);
    ASL_T1ROI_CBFaverage(mprpath,mprname,acbffile,rcbffile,dirrslt);
    
    % Normalize CBF map to MNI space
    tmpcbf_mni = [[tmppath filesep aslname '_aCBF_thre_MNI.img'];
                  [tmppath filesep aslname '_rCBF_thre_MNI.img']];
    outcbf_mni = [[dirrslt filesep aslname '_aCBF_thre_MNI.img'];
                  [dirrslt filesep aslname '_rCBF_thre_MNI.img']];
    
    for ii = 1:2
        cmd1 = [scriptpath filesep 'IMG_apply_AIR_tform1 ' ...
            outcbf_mpr(ii,:) ' ' tmpcbf_mni(ii,:) ' ' ...
            mprpath filesep 'matrix_air.txt 1 ' ...
            mprpath filesep 'mni.imgsize 1'];
        cmd2 = [scriptpath filesep 'IMG_change_res_info ' ...
            tmpcbf_mni(ii,:) ' ' tmpcbf_mni(ii,:) ' 1 1 1'];
        
        system(cmd1);
        system(cmd2);
        ASL_downSampleMNI(tmpcbf_mni(ii,:),outcbf_mni(ii,:));
    end

    % detect the abnormal CBF region
    if findabnorm
        rcbftpm_ave_s12 = [scriptpath filesep 'tpm' filesep 'rCBF_291control_MNI_s12mm_ave.img'];
        rcbftpm_std_s12 = [scriptpath filesep 'tpm' filesep 'rCBF_291control_MNI_s12mm_std.img'];
        rcbftpm_mask    = [scriptpath filesep 'tpm' filesep 'rCBF_291control_MNI_brainmask.img'];
        rcbf            = [dirrslt filesep aslname '_rCBF_thre_MNI.img'];
        ASL_findAbnormalCBF(rcbf,rcbftpm_ave_s12,rcbftpm_std_s12,rcbftpm_mask,dirrslt);
    end

end

%% zip output files & uploaded data for download
copyfile([datapath filesep aslname '.*'],dirrdat);
if M0data
    copyfile([datapath filesep M0name '.*'],dirrdat);
end
if MPRdata
    zip([dirrdat filesep 'T1_multiatlas_' mprname '.zip'],mprpath);
end
zipname = fullfile(outpath,['ASLMRICloud_Output_' aslname '.zip']);
% system(['zip -j ' zipname ' ' fullfile(outpath,'*.*')]);
zip(zipname,{dirrslt,dirrdat});

