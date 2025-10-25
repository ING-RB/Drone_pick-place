function hdr = getHeader(ip)
%

%   Copyright 2020 The MathWorks, Inc.

    if isscalar(ip)
        hdr = sprintf('IPv%d %s - %s\n', ip.Version, matlab.mixin.CustomDisplay.getClassNameForHeader(ip), string(ip));
    else
        hdr = matlab.mixin.CustomDisplay.getSimpleHeader(ip);
    end

    % LocalWords:  IPv
