function validateGeneratedPathname(pathName,propOrParamName)
% This function is undocumented and may change in a future release.

%  Copyright 2016-2024 The MathWorks, Inc.
import matlab.unittest.internal.mustBeTextScalar;

mustBeTextScalar(pathName);
pathName = char(pathName);

try
    matlab.unittest.internal.validatePathname(pathName);
catch err
    error(message('MATLAB:automation:io:FileIO:InvalidDueToInvalidPathname',propOrParamName,err.message));
end
end
