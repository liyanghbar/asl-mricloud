function mpr_brain = ASL_mprageSkullstrip(mproutpath, mprname)
% get the brain image by masking mpr image

mVol    = spm_vol([mproutpath filesep mprname '.img']);
mpr     = spm_read_vols(mVol);

if exist([mproutpath filesep mprname '_picsl_286Labels.img'],'file')
    roimaskfile = [mproutpath filesep mprname '_picsl_286Labels.img'] ;
else
    roimaskfile = [mproutpath filesep mprname '_286Labels.img'];
end
maskvol = spm_vol(roimaskfile);
allmask = spm_read_vols(maskvol);

p = [mproutpath filesep 'multilevel_lookup_table.txt'];
[n1,n2,n3,n4,n5,~,~,~,~,~,~] = textread(p,'%s %s %s %s %s %s %s %s %s %s %s');

nmask       = length(n1(2:end)); 
brainmask   = zeros(size(allmask));
for ii = 1:nmask
    if ~isempty(char(n5(ii+1)))
        brainmask(allmask==str2num(char(n1(ii+1)))) = 1;
    end
end

mpr_brain   = [mproutpath filesep mprname '_brain.img'];
mVol.fname  = mpr_brain;
spm_write_vol(mVol, mpr.*brainmask);


