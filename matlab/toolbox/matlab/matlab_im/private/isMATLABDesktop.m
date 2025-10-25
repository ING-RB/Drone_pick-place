function result = isMATLABDesktop
% This function returns true if the MATLAB session is Desktop
% and returns false for all non-desktop MATLAB sessions like
% MATLAB Mobile, MATLAB Online Server and more.

%   Copyright 2024 The MathWorks, Inc.

import matlab.internal.capability.Capability;
if Capability.isSupported(Capability.LocalClient)
    result = true;
else
    % This is running in MATLAB Online
    result = false;
end
end