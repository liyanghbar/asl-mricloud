%% Parameters inputted by user via web interface or predefined on server
clear variables
% Paths and uploaded file names

% datapath: Data folder on the server that contains the uploaded img/hdr files. 
% outpath: Output folder on the server contains the results to be downloaded by user. 
datapath    = 'C:\Users\yli199\Desktop\3T6546'; 
outpath     = [datapath '\output']; 
aslname     = '3T6546_ASL_2D'; % ASL .img file name

M0data = 0; % Have img/hdr files of M0 scan? Yes - 1 or No - 0 (default)
if M0data == 1
    M0name = 'subject_m0'; % M0 .img file name
else
    M0name = ''; % If no M0 scan, use an empty string
end

MPRdata = 0; % Has the zip file of T1-MPRAGE results? Yes - 1 or No - 0 (default)
if MPRdata == 1;
    mprpath = 'E:\asl_mricloud_test\test_3d_pl_t1_tsapkini\jwe_160428_t1\output'; % Unzipped MPR folder
else
    mprpath = ''; % If no, use an empty string
end

% Acquisition parameters
lablschm    = 'pCASL'; % Labeling scheme: 'pCASL'(default), 'PASL', or 'pCASL_uclaSiemens'

UCLA_Siemens_pCASL = 0;
if strcmp(lablschm,'pCASL_uclaSiemens')
    lablschm    = 'pCASL';
    M0data      = 1;
    UCLA_Siemens_pCASL = 1;
end

order       = 'Control first'; % Control label order: 'Control first'(default) or 'Label first'
acqdim      = '2D'; % Acquisition scheme: '2D'(default) or '3D'
labldur     = 1650; % labeling duration (ms)
PLD         = 1525; % post-labeling delay (ms)
TI1         = 800;  % TI1 (ms)     
TI          = 1800; % TI (ms)
w           = 35 * strcmp(acqdim,'2D') + 0 * strcmp(acqdim,'3D'); % slice acquisition delay (ms)
applyBrnMsk = 1;

bgsup       = 0; % Have background suppression? Yes - '1' or No - '0'(default)
time_BS     = [1980,3220,0,0,0,3640]; %(labldur+PLD)*strcmp(lablschm,'pCASL')+TI*strcmp(lablschm,'PASL')];
num_BS      = 2; % Number of inversion pulse after labeling
alpha_BS    = 0.93; % Inversion efficiency

% M0 acquisition/estimation
M0_TR       = 8000; % TR of M0 scan
T1tissue    = 1165; %1165; % Tissue T1 (ms)
useGloM0in3D= 0;

% Assumptions
T1blood     = 1650; %1650; % Blood T1 (ms)
lambda      = 0.90; % Brain-blood partition coefficient
alpha_labl  = 0.85*strcmp(lablschm,'pCASL') + 0.98*strcmp(lablschm,'PASL'); % labeling efficiency
% alpha_labl  = 0.86*strcmp(lablschm,'pCASL') + 0.98*strcmp(lablschm,'PASL'); % labeling efficiency

% find abnormal CBF region?
findabnorm  = 0;

%% parameter group to be written in .json file
asl_paras.datapath    = datapath;
asl_paras.outpath     = outpath;
asl_paras.aslname     = aslname;
asl_paras.M0data      = M0data;
asl_paras.M0name      = M0name;
asl_paras.MPRdata     = MPRdata;
asl_paras.mprpath     = mprpath;
asl_paras.UCLA_Siemens_pCASL = UCLA_Siemens_pCASL;
asl_paras.findabnorm  = findabnorm;

asl_paras.lablschm    = lablschm;
asl_paras.order       = order;
asl_paras.acqdim      = acqdim;
asl_paras.labldur     = labldur;
asl_paras.PLD         = PLD;
asl_paras.TI1         = TI1;
asl_paras.TI          = TI;
asl_paras.w           = w;
asl_paras.applyBrnMsk = applyBrnMsk;

asl_paras.bgsup       = bgsup;
asl_paras.time_BS     = time_BS;
asl_paras.num_BS      = num_BS;
asl_paras.alpha_BS    = alpha_BS;

asl_paras.M0_TR       = M0_TR;
asl_paras.T1tissue    = T1tissue;
asl_paras.useGloM0in3D= useGloM0in3D;

asl_paras.T1blood     = T1blood;
asl_paras.lambda      = lambda;
asl_paras.alpha_labl  = alpha_labl;

%% Run pipeline
% Scriptpath: folder contains the two MNI-normalization functions.
scriptpath  = 'C:\Users\yli199\Documents\MATLAB\ASLcloud\asl_mricloud_yli';
spm12path   = 'C:\Users\yli199\Documents\MATLAB\spm12';
jsonpath    = 'C:\Users\yli199\Documents\MATLAB\jsonlab';
addpath(scriptpath,spm12path,jsonpath);
asl_paras_filename = 'asl_paras_2d.json';
savejson('',asl_paras,[datapath filesep asl_paras_filename]);

% datapath    = 'E:\asl_mricloud_test\test_3dgrase_binu';
asl_paras_filename = 'asl_paras_2d.json';

cfgfn = [datapath,filesep,asl_paras_filename];

tic
ASL_pipeline(scriptpath,cfgfn);
toc

