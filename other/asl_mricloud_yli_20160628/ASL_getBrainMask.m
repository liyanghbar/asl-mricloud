function mask = ASL_getBrainMask(imgtpm,imgfile)
% generate brain mask:
% if fov is more than half of the brain, use spm segmentation-based method.
% if fov is too thin, use threshold-based method.
% yli20160615

[imgpath,imgfn,ext] = fileparts(imgfile);
P = spm_select('FPList',imgpath,['^' imgfn '\' ext]);
V = spm_vol(P);
imgvol = spm_read_vols(V); imgvol(isnan(imgvol)) = 0;

fov = V(1).dim.*abs(V(1).mat(eye(4,3)==1))';

flag_small_fov = sum(fov<60) > 0;
% if any dimension is less than 60mm, it is small fov. Segmentation method probably will not work

switch flag_small_fov
    case 0 % segmentation-based method
        % initiate spm_jobman
        spm('defaults','fmri'); spm_jobman('initcfg');
        matlabbatch = [];
        
        ngaus  = [1 1 2 3 4 2];
        native = [1 1 1 0 0 0];
        for ii = 1:6
            matlabbatch{1}.spm.spatial.preproc.tissue(ii).tpm = {[imgtpm ',' num2str(ii)]};
            matlabbatch{1}.spm.spatial.preproc.tissue(ii).ngaus = ngaus(ii);
            matlabbatch{1}.spm.spatial.preproc.tissue(ii).native = [native(ii) 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(ii).warped = [0 0];
        end
        
        matlabbatch{1}.spm.spatial.preproc.channel.vols = {[imgfile ',1']};
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];
        
        spm_jobman('run',matlabbatch);
        
        % add GM WM CSF masks together to get brainmask
        [imgpath,~,~] = fileparts(imgfile);
        P = spm_select('FPList',imgpath,['^c.*\.nii']);
        V = spm_vol(P(1:3,:));
        mvol = spm_read_vols(V);
        mask = sum(mvol,4);
        
        mask = mask > 0.5;
        mask = imfill(mask,'holes');
        
        % dilate by 1 layer
        [xx,yy,zz]  = ndgrid(-1:1);
        se          = sqrt(xx.^2 + yy.^2 + zz.^2) <= 1;
        BW          = imdilate(mask,se);
        mask        = uint8(BW);
        
    case 1
        % define boundaries to average the brain voxels
        lowb            = 0.25;  % lower boundary = 25 percent from the low end
        highb           = 0.75;  % higher boundary = 75 percent from the low end (i.e., 25 percent from the high end)
        thre_scale      = 0.35;  % define the threshold in relative to the mean of in-boundary voxels
        mask = inbrain(imgvol,lowb,highb,thre_scale,3,3);
end
end


function brainmask = inbrain(varargin)
% Generate in-brain voxels using thresholding
image = varargin{1};
lowb  = varargin{2};
highb = varargin{3};
thre_scale = varargin{4};
erode_mod = 0;
if nargin > 4
    erode_mod = 1;
    erode_layer  = varargin{5};
    dilate_layer = varargin{6};
end

% Get a threshold
mat1 = size(image,1);
mat2 = size(image,2);
mat3 = size(image,3);
tmpmat = image( round(mat1*lowb):round(mat1*highb),...
                round(mat2*lowb):round(mat2*highb),...
                round(mat3*lowb):round(mat3*highb));
tmpvox = tmpmat(tmpmat>0);
thre = mean(tmpvox)*thre_scale;

mask1 = zeros(size(image));
mask1(image>thre) = 1;
mask1 = imfill(mask1,'holes');

if erode_mod == 0
    brainmask = uint8(mask1);
else % erode mask1
    [xx,yy,zz] = ndgrid(-1:1);
    se = sqrt(xx.^2 + yy.^2 + zz.^2) <= 1;
    BW = mask1;
    for ii = 1:erode_layer
        BW = imerode(BW,se);
    end
    % find largest cluster
    CC = bwconncomp(BW);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [~,idx] = max(numPixels);
    mask2 = zeros(size(mask1));
    mask2(CC.PixelIdxList{idx}) = 1;
    % dilate mask2
    BW2 = mask2;
    for ii = 1:dilate_layer
        BW2 = imdilate(BW2,se);
    end
    brainmask = uint8(BW2.*mask1);
end
end

