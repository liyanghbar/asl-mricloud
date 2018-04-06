tgt = 'E:\asl_mricloud_test\test_singl_tsapkini\path_data\scn_160415\scn_160415\scn_160415_mpr_brain.img';
src = 'E:\asl_mricloud_test\test_singl_tsapkini\path_data\temp_scn_160415_pcasl\rscn_160415_m0_m0ave.img';
otr = 'E:\asl_mricloud_test\test_singl_tsapkini\path_data\temp_scn_160415_pcasl\rscn_160415_m0_brnmsk_clcu.img';

asl_coregister(tgt,src,otr);

path_mpr    = 'Y:\Documents\MATLAB\test_singl_tsapkini\path_data\scn_160415\scn_160415';
name_mpr    = 'scn_160415_mpr';
acbffile    = 'Y:\Documents\MATLAB\test_singl_tsapkini\path_output\ASLMRICloud_Output_scn_160415_pcasl\results\scn_160415_pcasl_aCBF_thre_mpr.img';
rcbffile    = 'Y:\Documents\MATLAB\test_singl_tsapkini\path_output\ASLMRICloud_Output_scn_160415_pcasl\results\scn_160415_pcasl_rCBF_thre_mpr.img';
rmskfile    = '';
outpath     = 'C:\Users\yli199\Desktop';


ASL_T1ROI_CBFaverage(path_mpr,name_mpr,acbffile,rcbffile,rmskfile,outpath);

% multidelay test
