function fullName = folderResolver(folder)
% This function is undocumented.

%  Copyright 2015-2024 The MathWorks, Inc.
import matlab.automation.internal.mustBeTextScalar;
import matlab.automation.internal.mustContainCharacters;
mustBeTextScalar(folder,'folder');
mustContainCharacters(folder,'folder');


try
    canonicalizedFolder =  builtin('_canonicalizepath',folder);
catch
    error(message('MATLAB:automation:io:FileIO:InvalidFolder', folder));
end
[status, folderInfo] = fileattrib(canonicalizedFolder);
if ~(status && folderInfo.directory)
    error(message('MATLAB:automation:io:FileIO:InvalidFolder', folder));
end

fullName = folderInfo.Name;
end

