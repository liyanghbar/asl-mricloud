function ASL_calculateM0(path_temp,path_code,asl_paras)
% This function obtains M0 global value (when no M0 scan) or map (dedicated
% M0 scan) for ASL analysis
% output:
%   M0map       (datatype, double ), used for cbf quantification;
%   brnmsk_dspl (datatype, logical), used for cbf map display;
%   brnmsk_clcu (datatype, logical), used for glo_cbf calculation.
% Peiying Liu, Oct 7, 2015; yli20160615

disp(['ASLMRICloud: (' asl_paras.SINGLPROC.name_asl ') Calculate M0 volume...']);

name_asl        = asl_paras.SINGLPROC.name_asl;

casl_dur        = asl_paras.BASICPARA.casl_dur;             
casl_pld        = asl_paras.BASICPARA.casl_pld;             
pasl_ti         = asl_paras.BASICPARA.pasl_ti;              
slic_dur        = asl_paras.BASICPARA.slic_dur; 
labl_schm       = asl_paras.BASICPARA.labl_schm;
scan_mode       = asl_paras.BASICPARA.scan_mode;   

flag_bgs        = asl_paras.BGSUPPRES.flag_bgs;
bgsu_time        = asl_paras.BGSUPPRES.bgsu_time; bgsu_time = sort(bgsu_time(bgsu_time~=0));
bgsu_eff         = asl_paras.BGSUPPRES.bgsu_eff;

flag_m0         = asl_paras.SINGLPROC.flag_m0;
name_m0         = asl_paras.SINGLPROC.name_m0;
m0_tr			= asl_paras.M0QUANEST.m0_tr;	
t1_tissue		= asl_paras.M0QUANEST.t1_tissue;

useGloM0in3D    = asl_paras.OTHERPARA.useGloM0in3D;


% provide target/tpm
imgtpm = [path_code filesep 'tpm' filesep 'TPM.nii'];
target = [path_temp filesep 'mean' name_asl '.img'];

% read the ctrl image
P_ctrl = spm_select('FPList',path_temp,['^r' name_asl '_ctrl\.img$']);
V_ctrl = spm_vol(P_ctrl);
ctrlvol  = spm_read_vols(V_ctrl); ctrlvol(isnan(ctrlvol)) = 0;
ctrlsiz  = size(ctrlvol);

if flag_m0 == 1 % if M0 map is uploaded
    % get M0 map
    P_m0    = spm_select('FPList',path_temp,['^' name_m0 '.*\.img']);
    V_m0    = spm_vol(P_m0);
    m0siz   = V_m0(1).dim;
    m0all   = spm_read_vols(V_m0); m0all(isnan(m0all)) = 0;
    m0map   = mean(m0all,4);
    ovol    = V_m0(1);
    ovol.fname = strrep(ovol.fname,name_m0,[name_asl '_m0ave']);
    ovol.dt = [16 0];
    spm_write_vol(ovol,m0map);
    
    if sum(ctrlsiz == m0siz) == 3 % have same dim with ctrl image
        % Coregister M0 map to ASL map
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
        [brnmsk_dspl, brnmsk_clcu] = ASL_getBrainMask(imgtpm,P_rm0,1);
        if useGloM0in3D
            m0_glo  = mean( rm0vol(brnmsk_clcu) );
            m0map   = double(brnmsk_dspl) * m0_glo;
        else
            m0map   = rm0vol.*double(brnmsk_dspl);
        end
    else % different dim with ctrl, then calculate m0_glo
        P_am0       = spm_select('FPList',path_temp, ['^' name_asl '_m0ave.img']);
        V_am0       = spm_vol(P_am0);
        am0vol      = spm_read_vols(V_am0); am0vol(isnan(am0vol)) = 0;
        if m0_tr < 5000
            am0vol  = am0vol./(1-exp(-m0_tr/t1_tissue));
        end
        [~          , brnmsk1_clcu] = ASL_getBrainMask(imgtpm,P_am0,0);
        [brnmsk_dspl, brnmsk_clcu ] = ASL_getBrainMask(imgtpm,P_ctrl,1);
        m0_glo      = mean( am0vol(brnmsk1_clcu) );
        m0map       = double(brnmsk_dspl) * m0_glo;
    end
%     filename = name_m0;
    
elseif flag_m0 == 0 % if no M0, load ctrl image
    % correct for T1 recovery
    m0tmp  = zeros(size(ctrlvol));
    nslice = size(ctrlvol,3);
    totdur = (casl_dur+casl_pld)*strcmp(labl_schm,'pCASL')+pasl_ti*strcmp(labl_schm,'PASL');
    for kk = 1:nslice
        if flag_bgs == 0
            timing = [0 totdur+slic_dur*(kk-1)*strcmp(scan_mode,'2D')];
            flip   = [0 0];
        elseif flag_bgs == 1
            timing = [0 bgsu_time(1:end-1) bgsu_time(end)+slic_dur*(kk-1)*strcmp(scan_mode,'2D')];
            flip   = [0 pi*ones(1,length(bgsu_time)-1) 0];
        end
        bgs_f           = bgs_factor(0.0,t1_tissue,flip,timing,bgsu_eff);
        m0tmp(:,:,kk)   = ctrlvol(:,:,kk) / bgs_f;
    end
    
    % get brain mask
    [brnmsk_dspl, brnmsk_clcu]  = ASL_getBrainMask(imgtpm,P_ctrl,1);
    m0_glo                      = mean( m0tmp(brnmsk_clcu) );
    m0map                       = double(brnmsk_dspl) * m0_glo;
%     filename                    = name_asl;
end

% write M0 map and brain masks
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

end

function bgs_f = bgs_factor(mz0,t1_tissue,flip,timing,inv_eff)
% Calculate the factor that mz was bg-suppressed

mz = mz0;
for ii = 1:length(flip)-1
    slot = 1:(timing(ii+1) - timing(ii));
    if abs(flip(ii) - pi) < 1e-6
        ff = 2*inv_eff-1;
    else
        ff = 1;
    end
    
    mztmp  = 1 + ( mz*cos(flip(ii))*ff - 1 ) * exp(-slot/t1_tissue);
    mz     = mztmp(end);
end
bgs_f = mz;
end

