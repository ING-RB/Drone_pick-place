function file = whichFile(file)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022 The MathWorks, Inc.

arguments
    file (1,1) string
end

if strcmp(file, "file")
    clear file;
    file = which("file");
else
    file = which(file);
end

% There are scenarios where classes can get stuck in memory
% even though they are not on the path (for example if _mcheck is used on
% a class file off the path). Unfortunately, the only way it seems to
% protect ourselves from these scenarios is to check if the which
% command gives us the exact English string 'Not on MATLAB path'. If so,
% then we instead return an empty string.
if strcmp(file, "Not on MATLAB path")
    file = string.empty();
end

file = string(file);
end

% LocalWords:  mcheck