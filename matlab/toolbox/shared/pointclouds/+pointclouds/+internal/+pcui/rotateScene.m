function rotateScene(rotateStepProperties, horizontalRotate, rotateDirection, currentAxes)

udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

minLimit = min(udata.dataLimits);
maxLimit = max(udata.dataLimits);
viewAngle = currentAxes.CameraViewAngle;

rotateStepSize = rotateStepProperties(1);
rotateAngleMin = rotateStepProperties(2);
rotateAngleMax = rotateStepProperties(3);

theta = rotateDirection * max(min(rotateStepSize * (maxLimit - minLimit), rotateAngleMax), rotateAngleMin);

if horizontalRotate
    camorbit(currentAxes,theta,0);
else
    camorbit(currentAxes,0,theta);
end

currentAxes.CameraViewAngle = viewAngle;
end