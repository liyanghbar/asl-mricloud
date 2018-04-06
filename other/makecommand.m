

function c=makecommand(t,i)
% if isempty(str2num(t{2*i}))
%     if t{2*i}(1)~='''';
%         c=strcat('para.',t{2*i-1},'=','''',t{2*i},''';');
%     else c=strcat('para.',t{2*i-1},'=',t{2*i},';');
%     end
% else
    c=strcat('para.',t{2*i-1},'=','[',t{2*i},'];');
end

