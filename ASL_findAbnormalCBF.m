function ASL_findAbnormalCBF(rcbfmni,maskmni,rcbftpm_ave_s12,rcbftpm_std_s12,rcbftpm_mask,outpath)
% Abnormal cbf detection for ASL MriCloud
% yli20160907

alpha   = 0.005; % z-score threshold
smhw    = 12; % unit: mm

% load ave/std/mask rCBF templates from control group
rcbf_ave    = spm_read_vols(spm_vol(rcbftpm_ave_s12));
rcbf_std    = spm_read_vols(spm_vol(rcbftpm_std_s12));
rcbf_msk    = spm_read_vols(spm_vol(rcbftpm_mask));

% load and smooth subject rcbf image
PT          = spm_vol(rcbfmni);
PO          = PT;
PO.fname    = [rcbfmni(1:end-4) sprintf('_s%02dmm.img',smhw)];
spm_smooth(PT,PO.fname,smhw,0);
rcbf_ptt    = spm_read_vols(PO);
mask_patt   = spm_read_vols(spm_vol(maskmni)) > 0.5;
mask_ovlp   = rcbf_msk & mask_patt;

% calculate the z_map
z_map_ptt = (rcbf_ptt - rcbf_ave) ./ rcbf_std;
z_map_ptt = z_map_ptt .* mask_ovlp;
z_map_ptt(isnan(z_map_ptt)) = 0;

% compare z_map with z_value
z_val   = norminv(1 - alpha/2);
z_low   = z_map_ptt < -z_val;
z_hgh   = z_map_ptt >  z_val;

z_roi   = ones(size(z_map_ptt));
z_roi   = int16(z_roi) + int16(z_low) * (-1) + int16(z_hgh) * (+1);

% save abnormal CBF region mask
[~,fname,~] = fileparts(rcbfmni);
PZ       = PT;
PZ.dt    = [4 0];
PZ.fname = [outpath filesep fname '_AbnormalCBFregionMask.img'];
spm_write_vol(PZ,z_roi);

delete([rcbfmni(1:end-4) sprintf('_s%02dmm.*',smhw)]); % delete smoothed rCBF

% add information to the asl_paras file
asl_paras_print = {
    'Abnormal CBF region detection                : ', ['please refer to ANALYZE file "AbnormalCBFregionMask"']; % 1
    '                                               ', ['(hyper- and hypo-perfuion regions are labeled as 2 and 0, respectively)']; % 2
    };
fileID = fopen([outpath filesep 'asl_info.txt'],'a');
formatSpec = '%s %s\n';
fprintf(fileID,'\n');
fprintf(fileID,formatSpec,asl_paras_print{1,:});
fprintf(fileID,formatSpec,asl_paras_print{2,:});
fclose(fileID);
