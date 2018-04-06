function ASL_multiDelay_calculateM0(path_temp,path_code,asl_paras)
% calculate m0 map

disp(['ASLMRICloud: (' asl_paras.SINGLPROC.name_asl ') Calculate multi-delay M0 volume...']);

name_asl        = asl_paras.SINGLPROC.name_asl;

casl_dur        = asl_paras.BASICPARA.casl_dur;
casl_pld        = asl_paras.BASICPARA.casl_pld;
pasl_ti         = asl_paras.BASICPARA.pasl_ti;
flip_angle      = asl_paras.BASICPARA.flipangle_looklocker;
labl_schm       = asl_paras.BASICPARA.labl_schm;
slic_dur        = asl_paras.BASICPARA.slic_dur;
scan_mode       = asl_paras.BASICPARA.scan_mode;

flag_m0         = asl_paras.SINGLPROC.flag_m0;
name_m0         = asl_paras.SINGLPROC.name_m0;
m0_tr			= asl_paras.M0QUANEST.m0_tr;
t1_tissue		= asl_paras.M0QUANEST.t1_tissue;
flag_multidelay = asl_paras.BASICPARA.flag_multidelay;

% provide tpm
imgtpm = [path_code filesep 'tpm' filesep 'TPM.nii'];

% load all ctrl
fn_asl      = spm_select('FPList',path_temp,['^',name_asl,'.img$']);
fn_ctrl     = spm_select('FPList',path_temp,['^r',name_asl,'_ctrl.img$']);
V_asl       = spm_vol(fn_asl);
V_ctrl      = spm_vol(fn_ctrl);
img_all     = spm_read_vols(V_asl); img_all(isnan(img_all)) = 0;

if flag_m0 == 1 % if M0 map is uploaded
    % get M0 map
    P_m0    = spm_select('FPList',path_temp,['^' name_m0 '.*\.img']);
    V_m0    = spm_vol(P_m0);
    m0all   = spm_read_vols(V_m0); m0all(isnan(m0all)) = 0;
    m0map   = mean(m0all,4);
    ovol    = V_m0(1);
    ovol.fname = strrep(ovol.fname,name_m0,[name_asl '_m0ave']);
    ovol.dt = [16 0];
    spm_write_vol(ovol,m0map);
    
    % Coregister M0 map to ASL map
    target = fn_ctrl;
    source = [path_temp filesep name_asl '_m0ave.img'];
    ASL_coreg(target,source);
    
    % read in the coregistered M0 map
    P_rm0 = spm_select('FPList',path_temp, ['^r' name_asl '_m0ave.img$']);
    V_rm0 = spm_vol(P_rm0);
    rm0vol = spm_read_vols(V_rm0); rm0vol(isnan(rm0vol)) = 0;
    
    % Corrected for T1 decay if M0_TR < 5000
    if m0_tr < 5000
        rm0vol = rm0vol./(1-exp(-m0_tr/t1_tissue));
    end

    % get brain mask
    [brnmsk_dspl, brnmsk_clcu] = ASL_getBrainMask(imgtpm,P_rm0,0);
    m0map   = rm0vol.*double(brnmsk_dspl);

elseif flag_m0 == 0 % if no M0, load ctrl image
    % get brain mask
    [brnmsk_dspl, brnmsk_clcu] = ASL_getBrainMask(imgtpm,fn_ctrl,0);
    
    ctrl_last      = img_all(:,:,:,end-1);             % the control of last PLD
    m0_int         = mean(ctrl_last(brnmsk_clcu));     % calculate the initial value of M0
    
    ctrl_all       = img_all(:,:,:,1:2:end);
    ctrl_all       = reshape(ctrl_all,[],size(ctrl_all,4));
    
    idx_msk        = find(brnmsk_dspl);
    m0_map         = zeros(size(ctrl_last));
%     t1_map         = zeros(size(ctrl_last));
    
    switch [labl_schm '-' num2str(flag_multidelay)]
        case 'pCASL-1'
            nvol      = size(img_all,4);
            npld      = length(casl_pld);
            nave      = nvol / 2 / npld;
            plds      = reshape(repmat(casl_pld,nave,1),[],1);
            ff        = @(beta,x)ASL_func_recover(beta(1),beta(2),x);
            beta_init = [   m0_int, 1165]; % m0, t1 (ms)
            lowb      = [        0,    0];
            uppb      = [10*m0_int, 5000];
            
            for ivox = idx_msk'
                [~,~,islc] = ind2sub(size(brnmsk_dspl),ivox); % account for slice delay
                xdata = plds + casl_dur + (islc - 1) * slic_dur * strcmp(scan_mode,'2D'); % add casl_dur to correct timing, no need for cbf/att fitting
                ydata = ctrl_all(ivox,:)';
                beta1 = lsqcurvefit(ff,beta_init,xdata,ydata,lowb,uppb,optimset('Display','off')); % suppress msg
%                 t1_map(ivox) = beta1(2);
                m0_map(ivox) = beta1(1);
            end
            
        case 'PASL-1'
            nvol      = size(img_all,4);
            nti       = length(pasl_ti);
            nave      = nvol / 2 / nti;
            tis       = reshape(repmat(pasl_ti,nave,1),[],1);
            ff        = @(beta,x)ASL_func_recover(beta(1),beta(2),x,flip_angle,beta(3));
            beta_init = [   m0_int, 1165,         0]; % m0, t1, m0_int
            lowb      = [        0,    0,-10*m0_int];
            uppb      = [10*m0_int, 5000,  5*m0_int];
            
            for ivox = idx_msk'
                [~,~,islc] = ind2sub(size(brnmsk_dspl),ivox); % account for slice delay
                xdata = tis + (islc - 1) * slic_dur * strcmp(scan_mode,'2D');
                ydata = ctrl_all(ivox,:)';
                beta1 = lsqcurvefit(ff,beta_init,xdata,ydata,lowb,uppb,optimset('Display','off')); % suppress msg
%                 t1_map(ivox) = beta1(2);
                m0_map(ivox) = beta1(1);
            end
    end
    
    m0map   = m0_map.*double(brnmsk_dspl);
end

% write maps to temp path
ovol1       = spm_vol(fn_asl);
ovol2       = ovol1(1);
ovol2.fname = strcat(path_temp,filesep,'r',name_asl,'_m0map.img');
spm_write_vol(ovol2, m0_map);

ovol = V_ctrl;
ovol.fname = [path_temp filesep 'r' name_asl '_m0map.img'];
ovol.dt    = [16 0];
spm_write_vol(ovol,m0map);
ovol.fname = [path_temp filesep 'r' name_asl '_brnmsk_dspl.img'];
ovol.dt    = [4 0];
spm_write_vol(ovol,brnmsk_dspl);
ovol.fname = [path_temp filesep 'r' name_asl '_brnmsk_clcu.img'];
ovol.dt    = [4 0];
spm_write_vol(ovol,brnmsk_clcu);

