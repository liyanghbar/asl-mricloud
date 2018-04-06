function ASL_multiDelay_calculateCBFATT(path_temp,asl_paras)
% Purpose: use lsq fitting method to calculate CBF map and ATT map using
%         trust region algorithm, 
%         normalization: voxel-wise M0  
%         model: asl_1compartment_model_T1appEqualsT1b
% Author: Hongli Fan
% Date:   10/20/2017
% yli20171207

warning('off','all');

disp(['ASLMRICloud: (' asl_paras.SINGLPROC.name_asl ') Calculate multi-delay CBF and ATT maps...']);

name_asl        = asl_paras.SINGLPROC.name_asl;
flag_multidelay = asl_paras.BASICPARA.flag_multidelay;
labl_schm   = asl_paras.BASICPARA.labl_schm;

casl_dur    = asl_paras.BASICPARA.casl_dur/1000; % ms -> s
casl_pld    = asl_paras.BASICPARA.casl_pld/1000; % ms -> s
pasl_dur    = asl_paras.BASICPARA.pasl_ti1/1000; % ms -> s
pasl_ti     = asl_paras.BASICPARA.pasl_ti/1000;  % ms -> s
flip_angle  = asl_paras.BASICPARA.flipangle_looklocker;
slic_dur    = asl_paras.BASICPARA.slic_dur/1000; % ms -> s
scan_mode   = asl_paras.BASICPARA.scan_mode;

assum_paras.labl_eff    = asl_paras.CBFQUANTI.labl_eff;
assum_paras.t1_blood    = asl_paras.CBFQUANTI.t1_blood/1000; % ms -> s
assum_paras.part_coef   = asl_paras.CBFQUANTI.part_coef;

% load asl/m0map/brnmsk_dspl/brnmsk_clcu
fn_asl        = spm_select('FPList',path_temp,['^',name_asl,'.img$']);
fn_m0map       = spm_select('FPList',path_temp,['^r.*\_m0map.img$']);
fn_brnmsk_dspl = spm_select('FPList',path_temp,['^r.*\_brnmsk_dspl.img$']);
fn_brnmsk_clcu = spm_select('FPList',path_temp,['^r.*\_brnmsk_clcu.img$']);
img_all        = spm_read_vols(spm_vol(fn_asl));      img_all(isnan(img_all))          = 0;
m0map       = spm_read_vols(spm_vol(fn_m0map));       m0map(isnan(m0map))              = 0;
brnmsk_dspl = spm_read_vols(spm_vol(fn_brnmsk_dspl)); brnmsk_dspl(isnan(brnmsk_dspl))  = 0;
brnmsk_clcu = spm_read_vols(spm_vol(fn_brnmsk_clcu)); brnmsk_clcu(isnan(brnmsk_clcu))  = 0;
brnmsk_dspl = logical(brnmsk_dspl);
brnmsk_clcu = logical(brnmsk_clcu);

% nonlinear fitting to general kinetic model.
diff        = img_all(:,:,:,1:2:end) - img_all(:,:,:,2:2:end);
brnmsk1     = repmat(brnmsk_dspl,[1,1,1,size(diff,4)]);
m0map1      = repmat(m0map,[1,1,1,size(diff,4)]);
idx_msk     = find(brnmsk_dspl);
idx_msk1    = find(brnmsk1);
ndiff          = zeros(size(diff));               % normalize diff with m0
ndiff(idx_msk1) = diff(idx_msk1)./m0map1(idx_msk1);  % normalize diff with m0
ndiff          = reshape(ndiff,[],size(diff,4));

attmap = zeros(size(m0map));
cbfmap = zeros(size(m0map));
bolusdurmap = zeros(size(m0map));
 
switch [labl_schm '-' num2str(flag_multidelay)]
    case 'pCASL-1'
        nvol      = size(img_all,4);
        npld      = length(casl_pld);
        nave      = nvol / 2 / npld;
        plds      = reshape(repmat(casl_pld,nave,1),[],1);
        
        ff = @(beta,plds)ASL_func_gkm_pcasl_multidelay(beta(1),beta(2),casl_dur,plds,assum_paras);  % ms -> s
        beta_init = [ 60, 0.5]; % cbf (ml/100g/min), att (ms)
        lowb      = [  0, 0.1];
        uppb      = [200, 3.0];
        
        for ivox = idx_msk'
            [~,~,islc] = ind2sub(size(brnmsk_dspl),ivox); % account for slice delay
            xdata = plds + (islc - 1) * slic_dur * strcmp(scan_mode,'2D'); % no need to add casl_dur
            ydata = ndiff(ivox,:)';
            beta1 = lsqcurvefit(ff,beta_init,xdata,ydata,lowb,uppb,optimset('Display','off'));   % suppress msg
            cbfmap(ivox) = beta1(1);
            attmap(ivox) = beta1(2) * 1000; % s -> ms
        end
        
    case 'PASL-1'
        nvol      = size(img_all,4);
        nti       = length(pasl_ti);
        nave      = nvol / 2 / nti;
        tis       = reshape(repmat(pasl_ti,nave,1),[],1);
            
        ff = @(beta,tis)ASL_func_gkm_pasl_looklocker(beta(1),beta(2),beta(3),tis,flip_angle,assum_paras);
        if pasl_dur * 1000 ~= 800 % default value 800 ms !!
            beta_init = [ 60, 0.5, pasl_dur]; % cbf, att, bolus duration
            lowb      = [  0, 0.1, pasl_dur];
            uppb      = [200, 3.0, pasl_dur];
        else
            beta_init = [ 60, 0.5, 1.0];      % cbf, att, bolus duration
            lowb      = [  0, 0.1,   0];
            uppb      = [200, 3.0, 2.0];
        end
        
        for ivox = idx_msk'
            [~,~,islc] = ind2sub(size(brnmsk_dspl),ivox); % account for slice delay
            xdata = tis + (islc - 1) * slic_dur * strcmp(scan_mode,'2D');
            ydata = ndiff(ivox,:)';
            beta2 = lsqcurvefit(ff,beta_init,xdata,ydata,lowb,uppb,optimset('Display','off'));  % suppress msg
            cbfmap(ivox) = beta2(1);
            attmap(ivox) = beta2(2) * 1000; % s -> ms
            bolusdurmap(ivox) = beta2(3);
        end
end

% threshold CBF image to remove the dark/bright spots
cbf_glo = mean(cbfmap(brnmsk_clcu));
rcbfmap = cbfmap / cbf_glo;

% write aCBF/rCBF/ATT maps to temp path
ovol1       = spm_vol(fn_m0map);
ovol2       = ovol1;
ovol3       = ovol1;
ovol1.fname = strcat(path_temp,filesep,'r',name_asl,'_aCBF_native.img');
ovol2.fname = strcat(path_temp,filesep,'r',name_asl,'_rCBF_native.img');
ovol3.fname = strcat(path_temp,filesep,'r',name_asl,'_ATT_native.img');
spm_write_vol(ovol1, cbfmap);
spm_write_vol(ovol2,rcbfmap);
spm_write_vol(ovol3, attmap);

