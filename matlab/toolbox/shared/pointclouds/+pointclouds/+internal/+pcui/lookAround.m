function lookAround(panStepProperties, horizontalPan, panDirection, currentAxes)
% This helper pans the camera in point cloud visualization tools

% Copyright 2022 The MathWorks, Inc.

udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

minLimit = min(udata.dataLimits);
maxLimit = max(udata.dataLimits);
viewAngle = currentAxes.CameraViewAngle;

panStepSize = panStepProperties(1);
panAngleMin = panStepProperties(2);
panAngleMax = panStepProperties(3);

theta = panDirection * (max(min(panStepSize * (maxLimit - minLimit), panAngleMax), panAngleMin));

% Use camera as the coordinate system for rotation. This is done to be able
% to pan in all view angles.
if horizontalPan
    campan(currentAxes,theta,0,'camera');
else
    campan(currentAxes,0,theta,'camera');
end

currentAxes.CameraViewAngle = viewAngle;
end
