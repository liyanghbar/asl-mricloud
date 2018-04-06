function diff = ASL_calculateDiffMap(aslpath,asl_paras)
% Calculate difference map (CBF-weighted) and write out the ANALYZE files

aslname     = asl_paras.aslname;
order       = asl_paras.order;

% Load data
P = spm_select('FPList',aslpath,['^r' aslname '.*\.img']);
V = spm_vol(P);
img_all = spm_read_vols(V); img_all(isnan(img_all)) = 0;

% Calculate difference map
dyn = size(V,1);

switch order
    case 'Control first'
        ctrl = mean(img_all(:,:,:,1:2:dyn),4);
        labl = mean(img_all(:,:,:,2:2:dyn),4);
    case 'Label first'
        ctrl = mean(img_all(:,:,:,2:2:dyn),4);
        labl = mean(img_all(:,:,:,1:2:dyn),4);
end
diff = ctrl - labl;

% write averaged ctrl/labl/diff images
outVol    = V(1);
outVol.dt = [16 0];
outVol.fname = strcat(aslpath,filesep,'r',aslname,'_ctrl.img');
spm_write_vol(outVol, ctrl);
outVol.fname = strcat(aslpath,filesep,'r',aslname,'_labl.img');
spm_write_vol(outVol, labl);
outVol.fname = strcat(aslpath,filesep,'r',aslname,'_diff.img');
spm_write_vol(outVol, diff);
