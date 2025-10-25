function throwMacaNoSupportError(varargin)
% Throw an error if an attempt is made to use on maca64 platform.
% This function will be a No-op otherwise.

%   Copyright 2023 The MathWorks, Inc.

interface = varargin{1};
if computer("arch") == "maca64"
    throw(MException(message("instrument:general:macaNotSupported", interface)));
end
end
