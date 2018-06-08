% ASL main batch
clear variables

% prepare .json file 
% cfgfn = 'E:\asl_mricloud_test\test_singl_tsapkini\asl_paras_singl_tsapkini.json';
% cfgfn = 'E:\asl_mricloud_test\test_3d_ucla\asl_paras_3d_ucla.json';
% cfgfn = 'E:\asl_mricloud_test\test_ge_2vol\asl_paras_ge_2vol.json';
% cfgfn = 'E:\yli199\scandata-vcid\hlu_prisma_xl20180518\asl_paras_usc.json';
cfgfn = 'E:\yli199\scandata_tumor\hlu_xmr_ta011818\asl\asl_paras_singl_ta.json';

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
cfgfn = 'E:\asl_mricloud_test\v3-test-case\paper_fig_multidelay\asl_paras_md_pcasl_multifile.json';

% Run pipeline
path_code   = 'C:\Users\yli199\Documents\MATLAB\ASLcloud\asl_mricloud_yli';
spm12path   = 'C:\Users\yli199\Documents\MATLAB\spm12';
jsonpath    = 'C:\Users\yli199\Documents\MATLAB\jsonlab';
addpath(path_code,spm12path,jsonpath);
success     = ASL_pipeline_jobman(path_code,cfgfn);

%% test webpage
config_file = 'E:\asl_mricloud_fakepath\config.json';
config_file_out = 'E:\asl_mricloud_fakepath\config-formatted.json';
cf1 = loadjson(config_file);
savejson('',cf1,config_file_out);

