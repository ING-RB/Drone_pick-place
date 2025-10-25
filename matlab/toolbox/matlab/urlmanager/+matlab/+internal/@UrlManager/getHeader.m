function hdr = getHeader(obj)
%

%   Copyright 2020 The MathWorks, Inc.

if isscalar(obj)
    hdr = sprintf('%s (%s)\n', matlab.mixin.CustomDisplay.getClassNameForHeader(obj), obj.Environment);
else
    hdr = matlab.mixin.CustomDisplay.getSimpleHeader(obj);
end
end