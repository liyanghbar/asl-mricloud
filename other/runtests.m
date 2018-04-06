function runtests()
machinename = getmachinename();
switch machinename
    case 'Mac-PC'
        addpath('C:\Yue\Dropbox\codes\matlab\luhanzhang\PCASL_analysis_yli');        
        addpath('C:\Yue\Dropbox\codes\matlab\jsonlab');
        cd ('C:\Yue\Dropbox\codes\matlab\luhanzhang\PCASL_analysis_yli');
        ASL_pipeline('','pcasl_sample_10222015_configure.json');
%       system('PCASL_analysis_toYue_deploy.exe  C:\Yue\Dropbox\To_Yue\sub2_M0 C:\Yue\Dropbox\To_Yue\sub2_M0\output C:\Yue\Dropbox\codes\matlab\luhanzhang\PCASL_analysis_toYue\pcasl_sample_configure.json');
        % commandline: PCASL_analysis_toYue_deploy  C:\Yue\Dropbox\To_Yue\sub2_M0 C:\Yue\Dropbox\To_Yue\sub2_M0\output pcasl_sample_configure.txt
    case 'Morilab-PC'
%         Andreia_fmri_processing('\\tsclient\I\data', '\fmridebugtest', 2, 'C:\Users\Yue\Dropbox\codes\matlab\andreiafmri\fmri_preprocess_job.m','\\tsclient\I\data');
        Andreia_fmri_processing('\\tsclient\H\data\fmri_Yue', '4D_fmri', 2, 'C:\Users\Yue\Dropbox\codes\matlab\andreiafmri\fmri_preprocess_job.m','\\tsclient\H\data\fmri_Yue');
        
    case {'io20', 'io21', 'io22'} % io2x machines at cis
        PCASL_analysis('C:\Yue\Dropbox\To_Yue\sub2_M0', 'C:\Yue\Dropbox\To_Yue\sub2_M0\output','pcasl_sample_configure.txt');
    case {'localhost.localdomain'}
        addpath('/root/code/matlab/PCASL_analysis_yli');        
        addpath('/root/code/matlab/toolbox/jsonlab');
        cd ('/root/code/matlab/PCASL_analysis_yli');
        ASL_pipeline('/root/code/matlab/PCASL_analysis_yli',...
            'pcasl_sample_3D_linux_10222015_configure.json');
        
    otherwise
        error('unknown machinename, can''t build');
end        
% usage: Andreia_fmri_processing('E:\data\fmri_Yue', 'FEP2047_1_140905_test2', 2, 'C:\Yue\Dropbox\codes\matlab\andreiafmri\fmri_preprocess_job.m');
% deployed mode: Andreia_fmri_processing E:\data\fmri_Yue FEP2047_1_140905_test2 2 C:\Yue\Dropbox\codes\matlab\andreiafmri\fmri_preprocess_job.m
