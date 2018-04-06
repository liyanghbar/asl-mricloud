
yli = rotpages90(reshape(ndiff,64,64,[]),1);
fan = aslimg_diff;

figure, imshow([tilepages(yli), tilepages(yli-fan)],[-1e-4 1e-4]);

figure,plot(tis,ttime);

yy1 = ndiff(24*64+56,:)';
yy2 = squeeze(aslimg_diff(40,56,:));
figure,plot(yy1,yy2);


temp = lsqcurvefit('pasl_model_3P_1',[0.5,1,60],ttime,yy2,[0.1,0,0],[3,2,200]); % bat, bolus_dur, cbf

ff = @(beta,tis)ASL_func_gkm_pasl_looklocker(beta(1),beta(2),beta(3),ttime,flip_angle,assum_paras);

beta_init = [ 60, 0.5, 1.0];      % cbf, bat, bolus duration
lowb      = [  0, 0.1,   0];
uppb      = [200, 3.0, 2.0];

beta2 = lsqcurvefit(ff,beta_init,tis,yy1,lowb,uppb);
mm22   = ASL_func_gkm_pasl_looklocker(100,0.76,0.38,ttime,flip_angle,assum_paras);
% mm2    = ASL_func_gkm_pasl_looklocker(100,0.76,0.38,tis',35,assum_paras);

ff1 = @(beta,x)pasl_model_3P_1(beta,x);

beta3 = lsqcurvefit(ff1,[0.5,1,60],tis,yy1,[0.1,0,0],[3,2,200]);
mm33   = pasl_model_3P_1([0.76 0.38 100],ttime);

figure, plot(ttime,mm22); hold on;
plot(ttime,mm33); hold off;

