function file = whichFile(file)
% This function is undocumented and may change in a future release.

%  Copyright 2014-2018 The MathWorks, Inc.

if strcmp(file, 'file')
    clear file;
    file = which('file');
else
    file = which(file);
end

% There are scenarios where classes can get stuck in memory
% even though they are not on the path (for example if _mcheck is used on
% a class file off the path). Unfortunately, the only way it seems to
% protect ourselves from these scenarios is to chech if the which
% command gives us the exact english string 'Not on MATLAB path'. If so,
% then we instead return ''.
if strcmp(file,'Not on MATLAB path')
    file = '';
end
end