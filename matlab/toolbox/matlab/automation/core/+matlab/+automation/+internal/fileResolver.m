function fullName = fileResolver(file)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.automation.internal.mustBeTextScalar;
import matlab.automation.internal.mustContainCharacters;

mustBeTextScalar(file,'file');
mustContainCharacters(file,'file');

try
    canonicalizedFilename = builtin('_canonicalizepath',file);
catch
    error(message('MATLAB:automation:io:FileIO:InvalidFile', file));
end
[status, fileInfo] = fileattrib(canonicalizedFilename);
if ~status || fileInfo.directory
    error(message('MATLAB:automation:io:FileIO:InvalidFile', file));
end

fullName = fileInfo.Name;
end
