function ASL_rescale(path_data,path_temp,name_asl)
% Rescale data set with scaling factor and overwrite original data

% path_data    = asl_paras.DIRECTORY.path_data;
% path_temp    = asl_paras.SINGLPROC.path_temp;
% name_asl     = asl_paras.SINGLPROC.name_asl;

disp(['ASLMRICloud: (' name_asl ') Scale ASL/M0 data...']);

P = spm_select('FPList',path_data,['^' name_asl '.img']);
V = spm_vol(P);

ss = V(1).pinfo(1);

for ii = 1:length(V)
    data   = spm_read_vols(V(ii)); data(isnan(data)) = 0;
    outVol = V(ii);
    outVol = rmfield(outVol,'private');
    outVol.fname    = [path_temp filesep name_asl '.img'];
    outVol.mat      = V(1).mat;
    outVol.descrip  = '4D rescaled images';
    outVol.dt       = [16,0];
    outVol.pinfo    = [1;0;0];
    spm_write_vol(outVol,data/ss/ss);
%     spm_write_vol(outVol,data);
end

