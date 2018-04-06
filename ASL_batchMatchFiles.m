function [flist_asl, flist_xxx] = ASL_batchMatchFiles(P_asl, P_xxx)
% In batch mode, we suppose that user uploads three .zip packages, 
% containing ASL, M0 (optional), and T1-multiatlas (optional), 
% respectively. We have to find ASL, M0, and T1-seg that belongs to the 
% same dataset.
% Input:
%
% Output:
%       flist_asl, cell array with file names (no ext) of all ASL .img data;
% yli20161118

N_asl       = size(P_asl,1);
flist_asl   = cell(N_asl,1);
flist_xxx   = cell(N_asl,1);

for ii = 1:N_asl
    [~,name_asl,~]  = fileparts(strtrim(P_asl(ii,:)));
    flist_asl{ii}   = name_asl;
    idx_asl         = strfind(name_asl,'_');
    str_asl         = name_asl(1:idx_asl);
    
    for jj = 1:N_asl
        [~,name_xxx,~] = fileparts(P_xxx(jj,:));
        idx_xxx        = strfind(name_xxx,'_');
        str_xxx        = name_xxx(1:idx_xxx);

        if strcmp(str_asl,str_xxx)
            flist_xxx{ii} = name_xxx;
            break;
        end
    end
end

end