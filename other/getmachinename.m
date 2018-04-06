function machinename = getmachinename()
[~, machinename] = system('hostname');
% there is a newline \n at the end of string, remove it. 
machinename = textscan (machinename, '%s', 'delimiter', '\n');
machinename = machinename{1}{1};
