llfile = 'E:\asl_mricloud_test\test_multidelay_looklocker\pasl_looklocker_sampledata.img';
[imgvols,matsize,voxsize,dt,ss] = read_hdrimg(llfile);
size(imgvols);
figure, imshow(tilepages(squeeze(imgvols)));
for ii = 1:13
    imgfname = ['E:\asl_mricloud_test\test_multidelay_looklocker\pasl_looklocker_sampledata-' sprintf('%03d',ii) '.img'];
    idx = (ii-1)*48 + (1:48);
    imgarray = imgvols(:,:,:,idx);
    write_hdrimg(imgarray, imgfname, voxsize, dt, ss);
end


fname = 'E:\asl_mricloud_test\test_multidelay_4slices\path_data\pcasl_multidelay_sampledata-0x.img';
for ii = 1:7
    fname1 = strrep(fname,'x',num2str(ii));
    [imgvols, matsize, voxsize, dt, ss] = read_hdrimg(fname1);
    imgvols1 = repmat(imgvols,1,1,4,1); % figure, imshow(tilepages(imgvols1));
    
    fname1 = strrep(fname,'x',[num2str(ii) '-mslc']);
    write_hdrimg(imgvols1, fname1, voxsize, dt, ss);
end