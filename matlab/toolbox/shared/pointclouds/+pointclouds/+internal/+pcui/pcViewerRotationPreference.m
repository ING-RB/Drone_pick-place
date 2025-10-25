function pcViewerRotation = pcViewerRotationPreference()
% Returns true if the PCViewerRotation preference is enabled, otherwise
% returns false.

% Copyright 2018-2019 The MathWorks, Inc.

% NOTE: This preference is only available in the Computer Vision Toolbox.
% If the Computer Vision Toolbox is not available, this preference will not
% not be honored.

% Call upon settings API object.
Settings = settings;
% Get the current value of the preference.
pref = Settings.pointclouds.pcviewers.PCViewerRotation.ActiveValue;
pcViewerRotation = logical(pref);
