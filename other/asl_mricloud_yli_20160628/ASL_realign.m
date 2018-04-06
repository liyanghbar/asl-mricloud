function P = ASL_realign(aslpath, aslname)
% Motion correction

% Get image files
P = spm_select('FPList',aslpath,['^' aslname '.*\.img']);
V = spm_vol(P);

defaults = spm_get_defaults;
FlagsC = struct('quality',defaults.realign.estimate.quality,'fwhm',5,'rtm',0);
spm_realign(V, FlagsC);

which_writerealign = 2;
mean_writerealign  = 1;
FlagsR = struct('interp',defaults.realign.write.interp,...
    'wrap',defaults.realign.write.wrap,...
    'mask',false,... 
    'which',which_writerealign,'mean',mean_writerealign);
%     'mask',defaults.realign.write.mask,...
spm_reslice(P,FlagsR);