function ASL_pipeline(scriptpath, cfgfn)

% Load asl parameters
asl_paras   = loadjson(cfgfn);

% split M0 and ASL scan if 'UCLA Siemens pCASL' is the case
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
mprpath     = asl_paras.mprpath;


%%%%%%%%%%%%%% ASL analysis at native space %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creat new tmp folder for processing and output folder for output
tmppath = [datapath filesep 'tmp'];
if exist(tmppath,'dir')
    rmdir(tmppath,'s');
end
if exist(outpath,'dir')
    rmdir(outpath,'s');
end
mkdir(tmppath);
mkdir(outpath);

% print parameters into a text file
ASL_printParas(asl_paras);

% scale data using scaling factor
ASL_rescale(datapath,tmppath,aslname);
if M0data == 1
    ASL_rescale(datapath,tmppath,M0name);
end

% motion correction
ASL_realign(tmppath,aslname);
copyfile([tmppath filesep 'rp_' aslname '.txt'], ...
         [outpath filesep aslname '_motion_vectors.txt']);

% calculate ASL difference image
diff = ASL_calculateDiffMap(tmppath,asl_paras);

% calculate M0
imgtpm = [scriptpath filesep 'TPM.nii'];
target = [tmppath filesep 'mean' aslname '.img'];
[M0map,brainmask] = ASL_calculateM0(tmppath,target,imgtpm,asl_paras);

% quantify absolute/relative CBF and copy to output folder
ASL_calculateCBFmap(tmppath,diff,M0map,brainmask,asl_paras);
copyfile([tmppath filesep 'r' aslname '_aCBF_thre_native.hdr'],[outpath filesep aslname '_aCBF_thre_native.hdr']);
copyfile([tmppath filesep 'r' aslname '_aCBF_thre_native.img'],[outpath filesep aslname '_aCBF_thre_native.img']);
copyfile([tmppath filesep 'r' aslname '_rCBF_thre_native.hdr'],[outpath filesep aslname '_rCBF_thre_native.hdr']);
copyfile([tmppath filesep 'r' aslname '_rCBF_thre_native.img'],[outpath filesep aslname '_rCBF_thre_native.img']);


%%%%%%%%%%%%% ROI analysis using T1 based rois %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(mprpath) % If MPRAGE zipfolder has been uploaded, continue.
    % After performing T1-segmentation pipeline

    % Get mprage name
    tmpname  = spm_select('List',mprpath,'.*\_brain.img');
    mprname  = tmpname(1:end-10);
        
    % coregister CBF map to Skull-stripped MPRAGE
    mpr_brain = ASL_mprageSkullstrip(mprpath, mprname);
    target = mpr_brain;
    source = [tmppath filesep 'mean' aslname '.img'];
    other  = [tmppath filesep 'r' aslname '_aCBF_thre_native.img';
              tmppath filesep 'r' aslname '_rCBF_thre_native.img'];
    ASL_coregister(target,source,other);

    % copy CBF in mpr space to output folder
    copyfile([tmppath filesep 'rr' aslname '_aCBF_thre_native.img'],[outpath filesep aslname '_aCBF_thre_mpr.img']);
    copyfile([tmppath filesep 'rr' aslname '_aCBF_thre_native.hdr'],[outpath filesep aslname '_aCBF_thre_mpr.hdr']);
    copyfile([tmppath filesep 'rr' aslname '_rCBF_thre_native.img'],[outpath filesep aslname '_rCBF_thre_mpr.img']);
    copyfile([tmppath filesep 'rr' aslname '_rCBF_thre_native.hdr'],[outpath filesep aslname '_rCBF_thre_mpr.hdr']);
    
    % ROI analysis in native space
    outcbf_mpr  = [[outpath filesep aslname '_aCBF_thre_mpr.img'];
                   [outpath filesep aslname '_rCBF_thre_mpr.img']];
    acbffile    = outcbf_mpr(1,:);
    rcbffile    = outcbf_mpr(2,:);
    ASL_T1ROI_CBFaverage(mprpath,mprname,acbffile,rcbffile,outpath);
    
    % Normalize CBF map to MNI space
    tmpcbf_mni = [[tmppath filesep aslname '_aCBF_thre_MNI.img'];
                  [tmppath filesep aslname '_rCBF_thre_MNI.img']];
    outcbf_mni = [[outpath filesep aslname '_aCBF_thre_MNI.img'];
                  [outpath filesep aslname '_rCBF_thre_MNI.img']];
    
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
end

% zip output files
zipname = fullfile(outpath,'Result.zip');
system(['zip -j ' zipname ' ' fullfile(outpath,'*.*')]);

