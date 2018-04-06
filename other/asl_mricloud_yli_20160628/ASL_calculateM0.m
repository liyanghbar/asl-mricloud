function [M0map, brainmask] = ASL_calculateM0(tmppath,target,imgtpm,asl_paras)
% This function obtains M0 value or map for PCASL analysis
% 
% Input:
%    tmppath  : tmp folder that contains ASL img/hdr and M0 img/hdr files.
%    aslname  : The name of the ASL file.
%    M0name   : The name of the M0 file.
%
% Output:
%    M0 : One single number or a 3D matrix.
%    
% Peiying Liu, Oct 7, 2015; yli20160615

aslname     = asl_paras.aslname;
lablschm    = asl_paras.lablschm;
acqdim      = asl_paras.acqdim;
bgsup       = asl_paras.bgsup;
time_BS     = asl_paras.time_BS; time_BS = sort(time_BS(time_BS~=0));
alpha_BS    = asl_paras.alpha_BS;
M0name      = asl_paras.M0name;
M0_TR       = asl_paras.M0_TR;

labldur     = asl_paras.labldur;
PLD         = asl_paras.PLD;
TI          = asl_paras.TI;
w           = asl_paras.w;
T1tissue    = asl_paras.T1tissue;
  
if ~isempty(M0name) % If M0 map is uploaded
    % Get M0 map
    P = spm_select('FPList',tmppath,['^' M0name '.*\.img']);
    V = spm_vol(P);
    M0all = spm_read_vols(V); M0all(isnan(M0all)) = 0;
    M0map = mean(M0all,4);
    outVol = V(1);
    outVol.fname = strrep(outVol.fname,M0name,[M0name '_ave']);
    outVol.dt = [16 0];
    spm_write_vol(outVol,M0map);
        
    % Coregister M0 map to ASL map
    source = [tmppath filesep M0name '_ave.img'];
    other  = source;
    ASL_coregister(target,source,other)
    
    % read in the coregistered M0 map
    P_rM0 = spm_select('FPList',tmppath, ['^r' M0name '_ave\.img']);
    V_rM0 = spm_vol(P_rM0);
    rM0vol = spm_read_vols(V_rM0); rM0vol(isnan(rM0vol)) = 0;
    
    % Corrected for T1 decay if M0_TR <= 5000
    if M0_TR < 5000
        rM0vol = rM0vol./(1-exp(-M0_TR/T1tissue));
    end
    
    % get brain mask
    brainmask = ASL_getBrainMask(imgtpm,P_rM0);
    M0map     = rM0vol.*double(brainmask);
    
    % write M0 map and brain mask
    outVol = V_rM0;
    outVol.fname = [tmppath filesep 'r' M0name '_M0map.img'];
    outVol.dt = [16 0];
    spm_write_vol(outVol,M0map);
    outVol.fname = [tmppath filesep 'r' M0name '_brainmask.img'];
    outVol.dt = [4 0];
    spm_write_vol(outVol,brainmask);    
    
elseif isempty(M0name) % If no M0, load control image
    P_ctrl = spm_select('FPList',tmppath,['^r' aslname '_ctrl\.img']);
    V_ctrl = spm_vol(P_ctrl);
    ctrlvol  = spm_read_vols(V_ctrl); ctrlvol(isnan(ctrlvol)) = 0;
    
    % correct for T1 recovery
    M0tmp  = zeros(size(ctrlvol));
    nslice = size(ctrlvol,3);
    totdur = (labldur+PLD)*strcmp(lablschm,'pCASL')+TI*strcmp(lablschm,'PASL');
    for kk = 1:nslice
        if bgsup == 0
            timing = [0 totdur+w*(kk-1)*strcmp(acqdim,'2D')];
            flip   = [0 0];
        elseif bgsup == 1
            timing = [0 time_BS(1:end-1) time_BS(end)+w*(kk-1)*strcmp(acqdim,'2D')];
            flip   = [0 pi*ones(1,length(time_BS)-1) 0];
        end
        Mt_ini = 0;
        M0tmp(:,:,kk) = ctrlvol(:,:,kk)/bgs_factor(Mt_ini,T1tissue,flip,timing,alpha_BS);
    end
    
    % get brain mask
    brainmask = ASL_getBrainMask(imgtpm,P_ctrl);
    M0_global = mean(M0tmp(brainmask>0.5));
    M0map     = double(brainmask) * M0_global;
    
    % write M0 map and brain mask
    outVol = V_ctrl;
    outVol.fname = [tmppath filesep 'r' aslname '_M0map.img'];
    outVol.dt = [16 0];
    spm_write_vol(outVol,M0map);
    outVol.fname = [tmppath filesep 'r' aslname '_brainmask.img'];
    outVol.dt = [4 0];
    spm_write_vol(outVol,brainmask); 
end
end
    

function bgs_f = bgs_factor(Mt_ini,T1tissue,flip,timing,alpha_BS)
% Calculate the factor that Mt was bg-suppressed
Mt = [Mt_ini];
ff = 1;
for ii = 1:length(flip)-1
    slot = 1:timing(ii+1)-timing(ii);
    if (flip(ii) > pi-1e6*eps) && (flip(ii) < pi+1e6*eps)
        ff = 2*alpha_BS-1;
    elseif (flip(ii) > 0-1e6*eps) && (flip(ii) < 0+1e6*eps)
    	ff = 1;
    end

    Mt = [Mt 1 + ( Mt(end)*cos(flip(ii))*ff - 1 ) * exp(-slot/T1tissue)];
end
bgs_f = Mt(end);
end
