function para=getparameters(fn)
% [p.nucleustype,p.celltypes,p.wght.w1] =...
%     textread(fn,'%s \n %s \n %f');
% t = textread(fn, 'nucleus %s\n','delimiter','\n','commentstyle','matlab')
[t]= textread(fn, '%s','delimiter','=','commentstyle','matlab');

l=floor(length(t)/2);

for i=1:l
    c=makecommand(t,i);
    c;
    eval(c);
end
para;
for i=1:5
    str=['p',num2str(i)];
    if isfield(para,str)
        command=['para.',str,'.runname=para.runname'];
        eval(command);
    end
end
