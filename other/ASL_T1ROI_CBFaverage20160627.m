function ASL_T1ROI_CBFaverage(mprpath,mprname,roi_table,acbffile,rcbffile,outpath)
    % Updated on 12/14/2015 to use only "286Labels" file. The 9 brain segments were
    % generated from Type1-Level2. The 28 brain segments were generated from Type1-Level3.
    
    % get mask and CBF map
    if exist([mprpath filesep mprname '_picsl_286Labels.img'],'file')
        roimaskfile = [mprpath filesep mprname '_picsl_286Labels.img'] ;
    else
        roimaskfile = [mprpath filesep mprname '_286Labels.img'];
    end
    
    tmpvol0     = spm_vol(roimaskfile);
    tmpvol1     = spm_vol(acbffile);
    tmpvol2     = spm_vol(rcbffile);
    maskvol     = spm_read_vols(tmpvol0);
    acbf        = spm_read_vols(tmpvol1); acbf(isnan(acbf)) = 0;
    rcbf        = spm_read_vols(tmpvol2); rcbf(isnan(rcbf)) = 0;
    
    % get ROI index
    pp = [mprpath filesep 'multilevel_lookup_table.txt'];
    [n1,n2,~,n4,n5,~,~,~,~,~,~] = textread(pp,'%s %s %s %s %s %s %s %s %s %s %s');
    roiindx = str2num(char(n1(2:end)));
    nummask = length(roiindx);

    % Combine parcellations to 9 (Type1-L2) or 28 (Type1-L3) segmentations
    roiinfo = { 19, 'Type1-L2', n5(2:end);
                53, 'Type1-L3', n4(2:end);
               286, 'Type1-L5', n2(2:end)};
            
    [~,cbffname,~] = fileparts(acbffile);
    fresult  = [outpath filesep cbffname(1:end-14) '_CBF_T1segmented_ROIs.txt'];
    f        = fopen(fresult, 'wt');
    coltitle = 'ROI analysis by %d major tissue types\n';
    colnames = 'Index\tMask_name\tRegional_CBF(ml/100g/min)\tRegional_relative_CBF\tNumber_of_voxels\n';
    colformt = '%d\t%s\t%1.2f\t%1.2f\t%u\n';
    
    for tt = 1:length(roiinfo)-1
    	roiall  = roiinfo{tt,3};
        roilist = list_roi_names(roi_table,roiinfo{tt,2});
        segindx = zeros(size(roilist));
        segmask = zeros(size(maskvol));
        
        for ii = 1:nummask
            for jj = 1:length(roilist)
                if strcmp(roilist{jj},roiall{ii})
                    segindx(jj)                   = jj;
                    segmask(maskvol==roiindx(ii)) = jj;
                end
            end
        end
        segfile = [outpath filesep mprname '_' num2str(roiinfo{tt,1}) 'segments.img'];
        write_ANALYZE(segmask,segfile,size(segmask),[1 1 1],1,4,0,[0 0 0]);
    
        fprintf(f,coltitle,length(roilist));
        fprintf(f,colnames);
        for ii = 1:length(roilist)
            tmp1 = acbf(segmask == segindx(ii));
            tmp2 = rcbf(segmask == segindx(ii));
            seg_acbf = mean(tmp1(~isnan(tmp1)));
            seg_rcbf = mean(tmp2(~isnan(tmp2)));
            seg_num  = length(tmp1);
            segname  = roilist{ii};
            fprintf(f,colformt,segindx(ii),segname,seg_acbf,seg_rcbf,seg_num);
        end
        fprintf(f,'\n\n');
    end
    
    % 286 parcellations
    fprintf(f,coltitle,nummask);
    fprintf(f,colnames);
    for ii = 1:nummask
        tmp1 = acbf(maskvol == roiindx(ii));
        tmp2 = rcbf(maskvol == roiindx(ii));
        seg_acbf = mean(tmp1(~isnan(tmp1)));
        seg_rcbf = mean(tmp2(~isnan(tmp2)));
        seg_num = length(tmp1);
        segname = roiinfo{3,3}{ii};
        fprintf(f,colformt,roiindx(ii),segname,seg_acbf,seg_rcbf,seg_num);     
    end
    fclose('all');
end

function tmplist = list_roi_names(roi_table,roitype)
    fileid  = fopen(roi_table);
    tmp     = textscan(fileid,'%s'); fclose(fileid);
    CC      = tmp{:};
    
    idx_beg = find(ismember(CC,['##' roitype '_BEG']))+1;
    idx_end = find(ismember(CC,['##' roitype '_END']))-1;
    tmplist = CC(int64(idx_beg:idx_end));
end

function f = write_ANALYZE(varargin)

    ImageArray = varargin{1};
    filename = varargin{2};
    mat_123 = varargin{3};
    mat_123 = reshape(mat_123,1,3);

    if nargin > 3 
       resolution = varargin{4};
       resolution = reshape(resolution,1,3);
    else 
       resolution = [1 1 1];
    end;

    if nargin > 4
       scale_factor = varargin{5};
    else
       scale_factor = 1;
    end;

    if nargin > 5
       data_type = varargin{6};
    else
       data_type = 4;
    end;

    if nargin > 6
       no_header = varargin{7};
    else
       no_header = 0;
    end;

    if nargin > 7
       mat_origin = varargin{8};
    else
       mat_origin = round(mat_123/2);
    end;

    ImageArray = ImageArray * scale_factor;

    [fname_path fname_body fname_ext] = fileparts(filename);
       fid_scan = fopen(fullfile(fname_path, [fname_body '.img']),'w'); 

          if data_type == 4
             fwrite(fid_scan,reshape(ImageArray,mat_123(1)*mat_123(2)*mat_123(3),1),'int16');
          elseif data_type == 2
             fwrite(fid_scan,reshape(ImageArray,mat_123(1)*mat_123(2)*mat_123(3),1),'uint8');
          elseif data_type == 16
             fwrite(fid_scan,reshape(ImageArray,mat_123(1)*mat_123(2)*mat_123(3),1),'float');
          elseif data_type == 64
             fwrite(fid_scan,reshape(ImageArray,mat_123(1)*mat_123(2)*mat_123(3),1),'double');
          end;          
        fclose(fid_scan);

        if no_header == 0
        P = fullfile(fname_path, [fname_body '.hdr']);

        DIM = mat_123;
        VOX = resolution;
        SCALE = 1;
        TYPE = data_type;
        OFFSET = 0;
        ORIGIN = mat_origin;
        DESCRIP = '';
        write_analyze75_header(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP);
    end;
end

function f = write_analyze75_header(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP)
    % writes an ANALYZE header 
    % modified from spm_hwrite.m
    %
    % P       - filename 	     (e.g 'spm' or 'spm.img')
    % DIM     - image size       [i j k [l]] (voxels)
    % VOX     - voxel size       [x y z [t]] (mm [sec])
    % SCALE   - scale factor
    % TYPE    - datatype (integer - see spm_type)
    % OFFSET  - offset (bytes)
    % ORIGIN  - [i j k] of origin  (default = [0 0 0])
    % DESCRIP - description string (default = 'spm compatible')
    %

    P               = P(P ~= ' ');
    q    		= length(P);
    if q>=4 & P(q - 3) == '.', P = P(1:(q - 4)); end;
    P     		= [P '.hdr'];

    fid             = fopen(P,'w','native');
    %fid             = fopen(P,'w','ieee-le');
    %fid             = fopen(P,'w','ieee-be');

    %---------------------------------------------------------------------------
    data_type 	= ['dsr      ' 0];

    P     		= [P '                  '];
    db_name		= [P(1:17) 0];

    % set header variables
    %---------------------------------------------------------------------------
    DIM		= DIM(:)'; if size(DIM,2) < 4; DIM = [DIM 1]; end
    VOX		= VOX(:)'; if size(VOX,2) < 4; VOX = [VOX 0]; end
    dim		= [4 DIM(1:4) 0 0 0];	
    pixdim		= [0 VOX(1:4) 0 0 0];
    vox_offset      = OFFSET;
    funused1	= SCALE;
    glmax		= 1;
    glmin		= 0;
    bitpix 		= 0;
    descrip         = zeros(1,80);
    aux_file        = ['none                   ' 0];
    origin          = [0 0 0 0 0];

    %---------------------------------------------------------------------------
    if TYPE == 1;   bitpix = 1;  glmax = 1;        glmin = 0;	end
    if TYPE == 2;   bitpix = 8;  glmax = 255;      glmin = 0;	end
    if TYPE == 4;   bitpix = 16; glmax = 32767;    glmin = 0;  	end
    if TYPE == 8;   bitpix = 32; glmax = (2^31-1); glmin = 0;	end
    if TYPE == 16;  bitpix = 32; glmax = 1;        glmin = 0;	end
    if TYPE == 64;  bitpix = 64; glmax = 1;        glmin = 0;	end

    %---------------------------------------------------------------------------
    if nargin >= 7; origin = [ORIGIN(:)' 0 0];  end
    if nargin <  8; DESCRIP = 'spm compatible'; end

    d          	= 1:min([length(DESCRIP) 79]);
    descrip(d) 	= DESCRIP(d);

    fseek(fid,0,'bof');

    % write (struct) header_key
    %---------------------------------------------------------------------------
    fwrite(fid,348,		'int32');
    fwrite(fid,data_type,	'char' );
    fwrite(fid,db_name,	'char' );
    fwrite(fid,0,		'int32');
    fwrite(fid,0,		'int16');
    fwrite(fid,'r',		'char' );
    fwrite(fid,'0',		'char' );

    % write (struct) image_dimension
    %---------------------------------------------------------------------------
    fseek(fid,40,'bof');

    fwrite(fid,dim,		'int16');
    fwrite(fid,'mm',	'char' );
    fwrite(fid,0,		'char' );
    fwrite(fid,0,		'char' );

    fwrite(fid,zeros(1,8),	'char' );
    fwrite(fid,0,		'int16');
    fwrite(fid,TYPE,	'int16');
    fwrite(fid,bitpix,	'int16');
    fwrite(fid,0,		'int16');
    fwrite(fid,pixdim,	'float');
    fwrite(fid,vox_offset,	'float');
    fwrite(fid,funused1,	'float');
    fwrite(fid,0,		'float');
    fwrite(fid,0,		'float');
    fwrite(fid,0,		'float');
    fwrite(fid,0,		'float');
    fwrite(fid,0,		'int32');
    fwrite(fid,0,		'int32');
    fwrite(fid,glmax,	'int32');
    fwrite(fid,glmin,	'int32');

    % write (struct) image_dimension
    %---------------------------------------------------------------------------
    fwrite(fid,descrip,	'char');
    fwrite(fid,aux_file,    'char');
    fwrite(fid,0,           'char');
    fwrite(fid,origin,      'int16');

    if fwrite(fid,zeros(1,85), 'char')~=85
        fclose(fid);
    end

    fclose(fid);
end