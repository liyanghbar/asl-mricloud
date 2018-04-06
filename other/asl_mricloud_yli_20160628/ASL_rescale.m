function ASL_rescale(datapath, tmppath, aslname)
% Rescale data set with scaling factor and overwrite original data
P = spm_select('FPList',datapath,['^' aslname '.img']);
V = spm_vol(P);

ss = V(1).pinfo(1);

for ii = 1:length(V)
    data   = spm_read_vols(V(ii)); data(isnan(data)) = 0;
    outVol = V(ii);
    outVol = rmfield(outVol,'private');
    outVol.fname    = [tmppath filesep aslname '.img'];
    outVol.mat      = V(1).mat;
    outVol.descrip  = '4D rescaled images';
    outVol.dt       = [16,0];
    outVol.pinfo    = [1;0;0];
    spm_write_vol(outVol,data/ss/ss);
%     spm_write_vol(outVol,data);
end

