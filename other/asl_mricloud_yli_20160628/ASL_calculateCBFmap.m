function ASL_calculateCBFmap(tmppath,diff,M0map,brainmask,asl_paras)
% This function obtains CBF value in the unit of ml/100g/min
%
% Input:
%    tmppath : data folder that contains ASL PAR/REC and M0 PAR/REC files.
%    aslname  : The name of the ASL file.
%    M0name   : The name of the M0 file.
%    Sind     : slice used to draw ROI to obtain M0
%
% Output:
%    M0 : One single number or a 3D matrix.
%
% Peiying Liu, Oct 7, 2015

aslname     = asl_paras.aslname;
acqdim      = asl_paras.acqdim;
lablschm    = asl_paras.lablschm;
% M0name      = asl_paras.M0name;
labldur     = asl_paras.labldur;
PLD         = asl_paras.PLD;
TI1         = asl_paras.TI1;
TI          = asl_paras.TI;
w           = asl_paras.w;
T1blood     = asl_paras.T1blood;
lambda      = asl_paras.lambda;
alpha_labl  = asl_paras.alpha_labl;
bgsup       = asl_paras.bgsup;
alpha_BS    = asl_paras.alpha_BS;
num_BS      = asl_paras.num_BS;

tmp     = zeros(size(diff));
nslice  = size(tmp,3);
% calculate absolute CBF without M0/mask/constant
switch lablschm
    case 'pCASL'
        for kk = 1:nslice
            sPLD = PLD + w*(kk-1)*strcmp(acqdim,'2D'); % correct delay for each slice
            tmp(:,:,kk) = diff(:,:,kk)*exp(sPLD/T1blood)/(1-exp(-labldur/T1blood))/T1blood;
        end
    case 'PASL'
        for kk = 1:nslice
            sTI = TI + w*(kk-1)*strcmp(acqdim,'2D');
            tmp(:,:,kk) = diff(:,:,kk)*exp(sTI/T1blood)/TI1;
        end
    case 'VS-ASL' % Not deployed yet
        for kk = 1:nslice
            sPLD = PLD + w*(kk-1)*strcmp(acqdim,'2D'); 
            tmp(:,:,kk) = diff(:,:,kk)*2*exp(sPLD/T1blood)/sPLD; % Bipolar gradient is necessary??
        end
end

% if ~isempty(M0name)
%     M0vol = double(M0map);
%     brainvol = double(brainmask);
% else
%     M0vol = ones(size(M0map))*mean(M0map(brainmask>0.5));
%     brainvol = ones(size(M0map));
% end

M0map(abs(M0map)<eps) = max(M0map(:))/2; % if border is missing due to motion and coreg

M0vol    = double(M0map);
brainvol = double(brainmask);
alpha    = (alpha_BS^num_BS*bgsup + 1*~bgsup) * alpha_labl;

cbf      = tmp ./ M0vol .* brainvol * lambda/2/alpha*60*100*1000;

% Thresholding CBF image to remove the dark spots and ultra bright spots in
% the raw data space
cbf_thr          = cbf;
cbf_thr(cbf<0)   = 0;
cbf_thr(cbf>200) = 200;
cbf_glo          = mean(cbf_thr(brainmask>0.5));
% rcbf             = cbf / cbf_glo;
rcbf_thr         = cbf_thr / cbf_glo;

% write out absolute/relative CBF maps
outVol = spm_vol([tmppath filesep 'r' aslname '_ctrl.img']);

outVol.fname = strcat(tmppath,filesep,'r',aslname,'_aCBF_thre_native.img');
spm_write_vol(outVol, cbf_thr);
outVol.fname = strcat(tmppath,filesep,'r',aslname,'_rCBF_thre_native.img');
spm_write_vol(outVol, rcbf_thr);
% outVol.fname = strcat(tmppath,filesep,'r',aslname,'_aCBF_native.img');
% spm_write_vol(outVol, cbf);
% outVol.fname = strcat(tmppath,filesep,'r',aslname,'_rCBF_native.img');
% spm_write_vol(outVol, rcbf);



