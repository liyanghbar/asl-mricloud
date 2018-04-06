function ASL_coregister(target,source,other)
% Coregister CBF map to MPRAGE or M0 map to ASL mean(ctrl+label) image

defaults = spm_get_defaults;
flags    = defaults.coreg;
mireg    = struct('VG',[],'VF',[],'PO','');
mireg.VG = spm_vol(target);
mireg.VF = spm_vol(source);
mireg.PO = other;
x  = spm_coreg(mireg.VG, mireg.VF,flags.estimate);
M  = inv(spm_matrix(x));
MM = zeros(4,4,size(mireg.PO,1));
for j=1:size(mireg.PO,1),
    MM(:,:,j) = spm_get_space(deblank(mireg.PO(j,:)));
end;
for j=1:size(mireg.PO,1),
    spm_get_space(deblank(mireg.PO(j,:)), M*MM(:,:,j));
end;
P         = char(mireg.VG.fname,mireg.PO);
flg       = flags.write;
flg.mean  = 0;
flg.which = 1;
flg.mean  = 0;
flg.mask  = false;
spm_reslice(P,flg);