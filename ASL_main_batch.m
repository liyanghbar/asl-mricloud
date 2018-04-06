% ASL main batch
clear variables

% prepare .json file 
cfgfn = 'E:\asl_mricloud_test\test_singl_tsapkini\asl_paras_singl_tsapkini.json';
% cfgfn = 'E:\asl_mricloud_test\test_3d_ucla\asl_paras_3d_ucla.json';
% cfgfn = 'E:\asl_mricloud_test\test_ge_2vol\asl_paras_ge_2vol.json';

% Run pipeline
path_code   = 'C:\Users\yli199\Documents\MATLAB\ASLcloud\asl_mricloud_yli';
spm12path   = 'C:\Users\yli199\Documents\MATLAB\spm12';
jsonpath    = 'C:\Users\yli199\Documents\MATLAB\jsonlab';
addpath(path_code,spm12path,jsonpath);
success     = ASL_pipeline_jobman(path_code,cfgfn);

%% multidelay test
clear variables

% prepare .json file 
% cfgfn = 'E:\asl_mricloud_test\test_multidelay\asl_paras_md_pcasl_multifile.json';
% cfgfn = 'E:\asl_mricloud_test\test_multidelay_looklocker\asl_paras_md_pcasl_multifile.json';
% cfgfn = 'E:\asl_mricloud_test\test_singl_tsapkini\asl_paras_singl_tsapkini.json'; % single-sub tsapkini test
% cfgfn = 'E:\asl_mricloud_test\test_batch_tsapkini\asl_paras_batch_tsapkini.json'; % batch tsapkini test
cfgfn = 'E:\asl_mricloud_test\test_multidelay_4slices\asl_paras_md_pcasl_multifile.json';

% Run pipeline
path_code   = 'C:\Users\yli199\Documents\MATLAB\ASLcloud\asl_mricloud_yli';
spm12path   = 'C:\Users\yli199\Documents\MATLAB\spm12';
jsonpath    = 'C:\Users\yli199\Documents\MATLAB\jsonlab';
addpath(path_code,spm12path,jsonpath);
success     = ASL_pipeline_jobman(path_code,cfgfn);

