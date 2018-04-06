function new_asl_paras = ASL_sortVols(asl_paras)
% ASL processing pipeline
% yli20171128

path_data       = asl_paras.DIRECTORY.path_data;
name_asl        = asl_paras.SINGLPROC.name_asl;
new_asl_paras   = asl_paras;
flag_m0         = asl_paras.SINGLPROC.flag_m0;
flag_multidelay = asl_paras.BASICPARA.flag_multidelay;

if flag_multidelay == 0
    % read in data
    disp(['ASLMRICloud: (' name_asl ') Sort out volumes...']);
    P = spm_select('FPList',path_data,['^' name_asl '.img$']);
    V = spm_vol(P);
    img_all = spm_read_vols(V); img_all(isnan(img_all)) = 0;

    nvol = size(V,1);
    
    if flag_m0 == 0
        % only ASL scan is uploaded
        
        if nvol == 2
            % GE two vol : diff, M0
            nex_m0  = 1; scale_m0 = 1 * nex_m0;
            nex_asl = 4; scale_asl = 32 * nex_asl;
            
            img_ctrl = img_all(:,:,:,2)/scale_m0;
            img_diff = img_all(:,:,:,1)/scale_asl;
            
            % write M0
            outVol          = V(1);
            outVol.dt       = [16 0]; % float
            outVol.fname    = [path_data filesep name_asl '_m0.img'];
            spm_write_vol(outVol,img_ctrl);
            % write ASL
            img_tmp = zeros(size(img_all));
            img_tmp(:,:,:,2) = img_ctrl - img_diff; % artificial label
            img_tmp(:,:,:,1) = img_ctrl; % artificial control
            
            for ii = 1:2
                outVol          = V(ii);
                outVol.n        = [ii,1];
                outVol.dt       = [16 0]; % float
                outVol.fname    = [path_data filesep name_asl '_asl.img'];
                spm_write_vol(outVol,img_tmp(:,:,:,ii));
            end
            
            % overwrite some asl_paras
            new_asl_paras.SINGLPROC.name_asl    = [name_asl '_asl'];
            new_asl_paras.SINGLPROC.name_m0     = [name_asl '_m0'];
            new_asl_paras.SINGLPROC.flag_m0     = 1;
            
        elseif nvol > 2
            dim0   = size(img_all);
            range1 = floor(dim0(1)/4) + (1:floor(dim0(1)/2));
            range2 = floor(dim0(2)/4) + (1:floor(dim0(2)/2));
            range3 = floor(dim0(3)/4) + (1:floor(dim0(3)/2));
            
            img_tmp = img_all(range1,range2,range3,:);
            img_rep = reshape(img_tmp,[],dim0(4));
            img_rep = mean(img_rep,1);
            [sig_max,idx_max] = max(img_rep);
            img_rep(idx_max) = [];
            std_rep = std(img_rep);
            ave_rep = mean(img_rep);
            %         idx = kmeans(img_rep',2);
            %         if sum(idx==1)==1 || sum(idx==2)==1
            if idx_max == 1 && sig_max > ave_rep + 5*std_rep
                % UCLA siemens protocol
                
                outVol          = V(1);
                outVol.mat      = V(1).mat;
                outVol.fname    = [path_data filesep name_asl '_m0.img'];
                spm_write_vol(outVol,img_all(:,:,:,1));
                
                for ii = 3:nvol
                    outVol          = V(ii);
                    outVol.n        = [ii-2,1];
                    outVol.fname    = [path_data filesep name_asl '_asl.img'];
                    spm_write_vol(outVol,img_all(:,:,:,ii));
                end
                
                % overwrite some asl_paras
                new_asl_paras.SINGLPROC.name_asl    = [name_asl '_asl'];
                new_asl_paras.SINGLPROC.name_m0     = [name_asl '_m0'];
                new_asl_paras.SINGLPROC.flag_m0     = 1;
            else
                % all ASL images, no M0
                % do nothing
                
            end
            
        end
        
    else
        % ASL scan & M0 scan are uploaded seperately
        % do nothing
    end
    
else
    % multi-delay ASL upload (default to have separate asl file)
    if iscell(name_asl) && length(name_asl) > 1 % multiple file of ASL
        disp(['ASLMRICloud: (' name_asl{1} ') Sort out volumes...']);
        asl_multi_list = strcat(path_data,filesep,name_asl','.img');
        asl_multi_list = char(asl_multi_list);
        P_multi = spm_vol(asl_multi_list);
        img_all = spm_read_vols(P_multi);
        nvol = length(P_multi);
        
        for ii = 1:nvol % separate/single -> write to one file
            ss              = P_multi(ii).pinfo(1);
            outVol          = P_multi(1);
            outVol.n        = [ii,1];
            outVol.dt       = [16,0];
            outVol.pinfo    = [1;0;0];
            outVol.fname    = [path_data filesep name_asl{1} '_asl_all.img'];
            spm_write_vol(outVol,img_all(:,:,:,ii)/ss/ss);
        end
        
        % overwrite some asl_paras
        new_asl_paras.SINGLPROC.name_asl    = [name_asl{1} '_asl_all'];
    else
        disp(['ASLMRICloud: (' name_asl ') Sort out volumes...']);
    end
end
    
