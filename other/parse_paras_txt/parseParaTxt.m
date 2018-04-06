% convert the asl_paras.txt to .json for parameters input on the interface
function parseParaTxt(paras_txt)

fstring = fileread(paras_txt);
fstring = strtrim(fstring);
fblocks = regexp(fstring,'[\n]','split');
fblocks = fblocks(2:end);
fblocks = fblocks(~cellfun('isempty',fblocks));

% fid = fopen(lookup_txt,'r');
% parafields = textscan(fid,'%s %s','delimiter',':');

lookup_txt = [
'lablschm 		: Labeling scheme                    \n' ...
'order 			: Control/label order                \n' ...
'acqdim 			: Acquisition scheme             \n' ...
'labldur 		: Labeling duration                  \n' ...
'PLD 			: Post-labeling delay                \n' ...
'TI1 			: TI1 time                           \n' ...
'TI 				: TI time                        \n' ...
'w 				: Slice acquisition duration         \n' ...
'bgsup			: Background suppression             \n' ...
'time_BS 		: Back. supp. pulse time             \n' ...
'num_BS			: Num. of inv. pulses after labeling \n' ...
'alpha_BS 		: Inversion efficiency               \n' ...
'M0_TR 			: TR of M0 scan                      \n' ...
'T1tissue		: Tissue T1                          \n' ...
'T1blood			: Blood T1                       \n' ...
'lambda 			: Brain/blood partition coeff.   \n' ...
'alpha_labl 		: Labeling efficiency            ' ];
lookup_txt = sprintf(lookup_txt);
parafields = textscan(lookup_txt,'%s %s','delimiter',':');

asl_paras = [];
for ii = 1 : length(parafields{1})
    match = 0;
    for kk = 1:numel(fblocks)
        parastr   = textscan(fblocks{kk},'%s %s','delimiter',':');
        paraname  = char(strtrim(parastr{1}));
        paravalue = char(strtrim(parastr{2}));
        
        if ~isempty(findstr(paraname,strtrim(parafields{2}{ii})))
            match = 1;
            break;
        end
    end
    
    if match
        if isempty(findstr('lablschm order acqdim bgsup',strtrim(parafields{1}{ii})))
            asl_paras.(strtrim(parafields{1}{ii})) = str2num(paravalue);
        else
            asl_paras.(strtrim(parafields{1}{ii})) = paravalue;
        end
    else
        asl_paras.(strtrim(parafields{1}{ii})) = [];
    end
end

asl_paras.UCLA_Siemens_pCASL    = 0;
if strcmp(asl_paras.lablschm,'UCLA_Siemens_pCASL')
    asl_paras.lablschm              = 'pCASL';
    asl_paras.UCLA_Siemens_pCASL    = 1;
end
asl_paras.bgsup = strcmp(asl_paras.bgsup,'Y');

[path,~,~] = fileparts(paras_txt);
savejson('',asl_paras,[path filesep 'asl_paras.json']);
% savejson('',asl_paras,['C:\Users\yli199\Desktop\asl_paras.json']);

end

