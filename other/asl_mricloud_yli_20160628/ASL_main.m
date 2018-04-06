%% Parameters inputted by user via web interface or predefined on server
clear all
% Paths and uploaded file names

% datapath: Data folder on the server that contains the uploaded img/hdr files. 
% outpath: Output folder on the server contains the results to be downloaded by user. 
datapath    = 'E:\asl_mricloud_test\test_3d_pl_t1_tsapkini'; 
outpath     = [datapath '\output']; 
aslname     = 'jwe_160428_pcasl'; % ASL .img file name

M0data = 1; % Have img/hdr files of M0 scan? Yes - 1 or No - 0 (default)
if M0data == 1
    M0name = 'jwe_160428_m0'; % M0 .img file name
else
    M0name = ''; % If no M0 scan, use an empty string
end

MPRdata = 1; % Has the zip file of T1-MPRAGE results? Yes - 1 or No - 0 (default)
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
acqdim      = '3D'; % Acquisition scheme: '2D'(default) or '3D'
labldur     = 1800; % labeling duration (ms)
PLD         = 1800; % post-labeling delay (ms)
TI1         = 800;  % TI1 (ms)     
TI          = 1800; % TI (ms)
w           = 35 * strcmp(acqdim,'2D') + 0 * strcmp(acqdim,'3D'); % slice acquisition delay (ms)

bgsup       = 1; % Have background suppression? Yes - '1' or No - '0'(default)
time_BS     = [1980,3220,0,0,0,3640]; %(labldur+PLD)*strcmp(lablschm,'pCASL')+TI*strcmp(lablschm,'PASL')];
num_BS      = 2; % Number of inversion pulse after labeling
alpha_BS    = 0.93; % Inversion efficiency

% M0 acquisition/estimation
M0_TR       = 4500; % TR of M0 scan
T1tissue    = 1165; % Tissue T1 (ms)

% Assumptions
T1blood     = 1650; % Blood T1 (ms)
lambda      = 0.90; % Brain-blood partition coefficient
alpha_labl  = 0.85*strcmp(lablschm,'pCASL') + 0.98*strcmp(lablschm,'PASL'); % labeling efficiency


%% parameter group to be written in .json file
asl_paras.datapath    = datapath;
asl_paras.outpath     = outpath;
asl_paras.aslname     = aslname;
asl_paras.M0data      = M0data;
asl_paras.M0name      = M0name;
asl_paras.MPRdata     = MPRdata;
asl_paras.mprpath     = mprpath;
asl_paras.UCLA_Siemens_pCASL = UCLA_Siemens_pCASL;

asl_paras.lablschm    = lablschm;
asl_paras.order       = order;
asl_paras.acqdim      = acqdim;
asl_paras.labldur     = labldur;
asl_paras.PLD         = PLD;
asl_paras.TI1         = TI1;
asl_paras.TI          = TI;
asl_paras.w           = w;

asl_paras.bgsup       = bgsup;
asl_paras.time_BS     = time_BS;
asl_paras.num_BS      = num_BS;
asl_paras.alpha_BS    = alpha_BS;

asl_paras.M0_TR       = M0_TR;
asl_paras.T1tissue    = T1tissue;

asl_paras.T1blood     = T1blood;
asl_paras.lambda      = lambda;
asl_paras.alpha_labl  = alpha_labl;

%% Run pipeline
% Scriptpath: folder contains the two MNI-normalization functions.
asl_paras_filename = 'asl_paras_3d_t1.json';
savejson('',asl_paras,[datapath filesep asl_paras_filename]);

scriptpath  = 'C:\Users\yli199\Documents\MATLAB\ASLcloud\PCASL_analysis_yli';  
cfgfn = [datapath,filesep,asl_paras_filename];

tic
ASL_pipeline(scriptpath,cfgfn);
toc
