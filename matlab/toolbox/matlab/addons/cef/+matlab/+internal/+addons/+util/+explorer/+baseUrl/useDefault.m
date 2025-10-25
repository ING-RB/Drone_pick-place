function useDefault
% Function to clear the preferred web service end point set
% and use the default web service end point

% Copyright 2020 The MathWorks, Inc.

    s = settings;
    if  s.matlab.addons.explorer.hasSetting("preferredEndPoint")
        s.matlab.addons.explorer.removeSetting("preferredEndPoint");
    end
end