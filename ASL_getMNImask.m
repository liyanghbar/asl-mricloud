function mask_mni = ASL_getMNImask(path_mpr, name_mpr)
% get the mask in mni space

roi_lookup_file = [path_mpr filesep 'multilevel_lookup_table.txt'];
roi_lookup_all  = read_roi_lookup_tabl(roi_lookup_file);
label_idx = str2num(char(roi_lookup_all{1,1}));
label_num = length(label_idx);
atlas_ver = num2str(label_num);

P0 = spm_select('FPList',path_mpr,['^' name_mpr '.*' atlas_ver 'Labels.*_MNI.img$']);
roimaskfile = P0(1,:);
maskvol = spm_vol(roimaskfile);
allmask = spm_read_vols(maskvol);

brainmask   = zeros(size(allmask));
for ii = 1:label_num
    if ~isempty(char(roi_lookup_all{1,5}{ii}))
        brainmask(allmask == label_idx(ii)) = 1;
    end
end

mask_mni   = [path_mpr filesep name_mpr '_mnimask111.img'];
maskvol.fname  = mask_mni;
spm_write_vol(maskvol, brainmask);
end

function roi_lookup_tabl = read_roi_lookup_tabl(roi_lookup_file)
fileid = fopen(roi_lookup_file);
title  = textscan(fileid,'%s',1,...
                    'delimiter','\n');

roi_lookup_tabl = textscan(fileid,repmat('%s ',1,11),...
                    'delimiter',{' ','\b','\t'},'MultipleDelimsAsOne',1);
                
fclose(fileid);
end


