% Purpose:use lsq fitting method to calculate CBFmap and BATmap 
%         trust region algorithm, 
%         normalization:voxel-wise M0  
%         model:asl_1compartment_model_T1appEqualsT1b
% Author:Hongli Fan
% Date:  10/20/2017


clear;close all;clc;
path=[];
subject=[];
scanID =[];
alpha=CBFQUANTI.labl_eff;
T1t=CBFQUANTI.t1_blood;
lambda=CBFQUANTI.part_coef;
tau=BASICPARA.casl_dur;
w=BASICPARA.casl_pld;          
Nphase = length(w);  

if size(w,1)>1           % convert w to be row vector
    w=w';
end
%% need brain mask here
maskindex=find(brnmsk);
masklength = length(maskindex);

%import the data
[r,c,s,v]=size(aslimg);    %aslimg is the 4D data
dyn_num=v/Nphase/2;
aslimg_reshape=reshape(aslimg,r,c,s,2*dyn_num,Nphase);
aslimg_ctl=aslimg_reshape(:,:,:,1:2:end,:);        %control image
aslimg_label=aslimg_reshape(:,:,:,2:2:end,:);      %label image
aslimg_diff=aslimg_ctl-aslimg_label;               %difference 
% for ix = 1:length(scanID)
%     header=par_read_header([path,'\',subject,'_',int2str(scanID(ix)),'_1.PAR']);
%     volume=par_read_volume(header);
%     aslimg=double(squeeze(volume));
%     fid = fopen([path,'\',subject,'_',int2str(scanID(ix)),'_1.PAR']);
%     line = fgetl(fid);
%     while ( length(line)<13)||(strcmp(line(1:13),'#  sl ec  dyn') == 0 )
%         line = fgetl(fid);
%     end
%     line = fgetl(fid);
%     line = fgetl(fid);
%     ss = str2double(line(69:80));
%     fclose(fid);
%     aslimg = aslimg/ss;
%     aslimg=aslimg/1e+6;
%     aslimg_ctl(:,:,:,ix)=imrotate(aslimg(:,:,1:2:end-1),90);
%     diff=aslimg(:,:,1:2:end-1)-aslimg(:,:,2:2:end);
%     diff=fimrotate(diff,90).*brnmsk;
%     aslimg_diff(:,:,:,ix)=diff;
% end
%% T1 saturation recovery to M0 map
ctl=aslimg_ctl(:,:,:,:,end);              %the control of last PLD
ctl_mean=mean(ctl,4);                     %mean control of last PLD
ctl_mean_brn=ctl_mean.*brnmsk;
M0_int=sum(ctl_mean_brn(:))/masklength;   %calculate the initial value of M0

T1map_reshape = zeros(r*c*s,1);
M0map_reshape = zeros(r*c*s,1);

ttime = w+tau;
ttime=repmat(ttime,[dyn_num,1]);
ttime=ttime(:);
beta0 = [1.165,M0_int];
for ix = 1:masklength
    [row,col,sli]=ind2sub([r,c,s],maskindex(ix));
    exp_S0=aslimg_ctl(row,col,sli,:);
    exp_S0=exp_S0(:);
    temp = lsqcurvefit('T1recovery',beta0,ttime,exp_S0,[0,0],[5,M0_int*10]);
    T1map_reshape(maskindex(ix)) = temp(1);
    M0map_reshape(maskindex(ix)) = temp(2);
end
T1map = reshape(T1map_reshape,r,c,s);
M0map = reshape(M0map_reshape,r,c,s);


%%  nonlinear fitting to general kinetic model.
brnmsk_d=repmat(brnmsk,[1,1,1,dyn_num,Nphase]);
M0map_d=repmat(M0map,[1,1,1,dyn_num,Nphase]);
I=find(brnmsk_d);
aslimg_diff(I)=aslimg_diff(I)./M0map_d(I);  %normalize diff signals

ATTmap=zeros(r,c,s);
CBFmap=zeros(r,c,s);
delay_all=repmat(w,[dyn_num,1]);
delay_all=delay_all(:);
for ix=1:length(maskindex)
    [row,col,sli]=ind2sub([r,c,s],maskindex(ix));
    exp_S0=squeeze(aslimg_diff(row,col,sli,:));
    exp_S0=exp_S0(:);
    f=@(beta,x)asl_1compartment_model_T1appEqualT1b(beta,x,alpha,lambda,tau,T1t);
    temp = lsqcurvefit(f,[1,60],delay_all,exp_S0,[0.1,0],[3,200]);
    ATTmap(row,col,sli)=temp(1);
    CBFmap(row,col,sli)=temp(2);
end

figure;imshow(CBFmap(:,:,1),[0,150],'border','tight','InitialMagnification',200,'colormap',hot);title('CBFmap');
figure;imshow(ATTmap(:,:,1),[0,3],'border','tight','InitialMagnification',200,'colormap',hot);title('BATmap');

