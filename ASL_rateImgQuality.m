function ASL_rateImgQuality(path_temp,asl_paras)
% rate the ASL image quality base on the standard error
% yli20161102

disp(['ASLMRICloud: (' asl_paras.SINGLPROC.name_asl ') Rate image quality...']);

name_asl     = asl_paras.SINGLPROC.name_asl;

% read the realigned asl data
P1 = spm_select('FPList',path_temp,['^r' name_asl '.img']);
P1 = spm_vol(P1);
imgall = spm_read_vols(P1);
repnum = size(imgall,4) / 2;
ctrl   = imgall(:,:,:,2:2:repnum * 2);
labl   = imgall(:,:,:,1:2:repnum * 2);
diff   = ctrl - labl;

% get brain mask
P2 = spm_select('FPList',path_temp,['^r.*_brnmsk_dspl.img']);
P2 = spm_vol(P2);
V2 = spm_read_vols(P2);
mask          = V2 > 0.5;
if size(mask,3) > 4
    mask(:,:,[1 2 end-1 end]) = 0; % remove boundary slices
end

% calculate SE as img quality idx
stdmap = std(diff,0,4);
avemap = mean(diff,4);
covmap = stdmap / abs(mean(avemap(mask)));
idx_se = mean(covmap(mask)) / sqrt(repnum);
% covmap = stdmap ./ abs(avemap); covmap(covmap==Inf) = 500;
% idx_se(ii) = mean(covmap(mask)) / sqrt(repnum/2);

rating = int16((idx_se-0.072)/0.265); % empirical equation, parameters from Park study (N=309)
rating = max(rating,1);
rating = min(rating,4);

% output to the asl_paras file
asl_paras_print = {
    '===================ASL IMAGE QUALITY CONTROL================= ', []; % 1
    'Image quality [from 1-Excellent to 4-Poor]   : ', []; % 2
    };
asl_paras_print{2,2} = num2str(rating);
fileID = fopen([asl_paras.SINGLPROC.path_output_subj_rslt filesep 'asl_info.txt'],'a');
formatSpec = '%s %s\n';
fprintf(fileID,'\n');
fprintf(fileID,formatSpec,asl_paras_print{1,:});
fprintf(fileID,formatSpec,asl_paras_print{2,:});
fclose(fileID);

