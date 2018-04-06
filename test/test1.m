assum_paras.t1_blood    = 1.25;
assum_paras.part_coef   = 0.9;
assum_paras.labl_eff    = 0.85;

plds = 0.1:0.1:3.0;
mm = ASL_func_gkm_pcasl_multidelay(60,1,1.2,plds',assum_paras);
beta=[1,60];
fan = asl_1compartment_model_T1appEqualT1b (beta,plds,0.85,0.9,1.2,1.25);

figure, plot(mm,'*'); hold on;
plot(fan); hold off;


assum_paras.t1_blood    = 1.65;
assum_paras.part_coef   = 0.9;
assum_paras.labl_eff    = 0.91;

tis = 0.04:0.3:5.0;
mm2 = ASL_func_gkm_pasl_looklocker(100,0.76,0.38,tis',35,assum_paras);

betax = [0.76,0.38,100]; % bat, bolus, cbf
fan2 = pasl_model_3P_1(betax,tis);

figure, plot(mm2,'o'); hold on;
plot(fan2); hold off;

% 