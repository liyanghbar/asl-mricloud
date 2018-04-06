% TI1: bolus duratuon. If users upload the parameter, it is the values the
%      user upload. Else, the default is 0.


path=[];
file=[];
alpha      = CBFQUANTI.labl_eff;
T1b        = CBFQUANTI.t1_blood;
lambda     = CBFQUANTI.part_coef;
tau        = BASICPARA.pasl_ti1;   % bolus duration
TI         = BASICPARA.pasl_ti;    % interval time
w          = BASICPARA.pasl_tis;   % inversion time points          
Nphase     = length(w); 
flip_angle = [];           % need flip angle 

if size(w,1)>1           % convert w to be row vector
    w=w';
end

%%import data
[r,c,s,v]  = size(aslimg);    % aslimg is the 4D data, the forth dimension is day_num*number of TI
dyn_num    = v/Nphase/2;
aslimg_reshape  = reshape(aslimg,r,c,s,2*dyn_num,Nphase);
aslimg_ctl      = aslimg_reshape(:,:,:,1:2:end,:);        % control image
aslimg_label    = aslimg_reshape(:,:,:,2:2:end,:);        % label image
aslimg_diff     = aslimg_ctl-aslimg_label;                % difference 
% header=par_read_header([path,'\' file]);
% volume=par_read_volume(header);
% aslimg=double(squeeze(volume));
% fid = fopen([path,'\' file]);
% line = fgetl(fid);
% while ( length(line)<13)||(strcmp(line(1:13),'#  sl ec  dyn') == 0 )
%      line = fgetl(fid);
% end
% line = fgetl(fid);
% line = fgetl(fid);
% ss = str2double(line(69:80));
% fclose(fid);
% aslimg=aslimg/ss;
% aslimg=aslimg/1e+6;
% aslimg_ctl=imrotate(aslimg(:,:,1:2:end-1),90);
% aslimg_diff=aslimg(:,:,1:2:end-1)-aslimg(:,:,2:2:end);
% aslimg_diff=imrotate(aslimg_diff,90);
% aslimg_diff_reshape=reshape(aslimg_diff,Nimg,Nimg,dyn_num,Nphase);
% aslimg_diff_ave=squeeze(mean(aslimg_diff_reshape,3));
% aslimg_diff_ave(aslimg_diff_ave<0)=0;

%% need brain mask
maskindex  = find(brnmsk);
masklength = length(maskindex);

%% calculate M0map
ctl           = aslimg_ctl(:,:,:,:,end);              % the control of last PLD
ctl_mean      = mean(ctl,4);                          % mean control of last PLD
ctl_mean_brn  = ctl_mean.*brnmsk;
M0_int        = sum(ctl_mean_brn(:))/masklength;      % calculate the initial value of M0
T1map_reshape = zeros(r*c*s,1);
M0map_reshape = zeros(r*c*s,1);

ttime   = repmat(w,[dyn_num,1]);ttime   = ttime(:);
beta0   = [1.165,M0_int];
f       = @(beta,x)LLrecovery(beta,x,flip_angle,TI);
for ix = 1:masklength
    [row,col,sli]  = ind2sub([r,c,s],maskindex(ix));
    exp_S0         = squeeze(aslimg_ctl(row,col,sli,:)); exp_S0 = exp_S0(:);
    beta     =   lsqcurvefit(f,beta0,ttime,exp_S0,[0,0],[5,M0_int*10]);
    T1map_reshape(maskindex(ix)) = beta(1);
    M0map_reshape(maskindex(ix)) = beta(2);
end

T1map = reshape(T1map_reshape,r,c,s);
M0map = reshape(M0map_reshape,r,c,s);

brnmsk_d       = repmat(brnmsk,[1,1,1,dyn_num,Nphase]);
M0map_d        = repmat(M0map,[1,1,1,dyn_num,Nphase]);
I              = find(brnmsk_d);
aslimg_diff(I) = aslimg_diff(I)./M0map_d(I);  % normalize diff signals

%% CBFmap and ATTmap fitting 
ATTmap      = zeros(r,c,s);
CBFmap      = zeros(r,c,s);
Durationmap = zeros(r,c,s); 
if tau
  f  = @(beta,x)pasl_model_2P(beta,x,T1b,TI,tau,lambda,labeff,flip_angle); 
  beta0 = [0.5,60];      % att, cbf
  lp    = [0.1,0];
  up    = [2.5,200];
  for ix=1:length(maskindex)
      [row,col,sli] = ind2sub([r,c,s],maskindex(ix));
      exp_S0        = squeeze(aslimg_diff(row,col,sli,:));exp_S0 = exp_S0(:);
      temp  =  lsqcurvefit(f,beta0,ttime,exp_S0,lp,up);
      ATTmap(row,col,sli)       = temp(1);   
      CBFmap(row,col,sli)       = temp(2);
  end 
  Durationmap(maskindex)  = tau;
else
   f = @(beta,x)pasl_model_3P(beta,x,T1b,TI,lambda,labeff,flip_angle); 
   beta0 = [0.5,1,60];   % att, bolus duration, cbf
   lp    = [0.1,0,0];
   up    = [2.5,2,200];
   for ix=1:length(maskindex)
      [row,col,sli] = ind2sub([r,c,s],maskindex(ix));
      exp_S0        = squeeze(aslimg_diff(row,col,sli,:));exp_S0 = exp_S0(:);
      temp  =  lsqcurvefit(f,beta0,ttime,exp_S0,lp,up);
      ATTmap(row,col,sli)       = temp(1);   
      Durationmap(row,col,sli)  = temp(2);
      CBFmap(row,col,sli)       = temp(3);
   end 
end





