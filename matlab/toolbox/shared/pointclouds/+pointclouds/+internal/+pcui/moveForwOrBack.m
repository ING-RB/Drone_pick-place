function moveForwOrBack(stepSize, currentAxes)

import pointclouds.internal.pcui.*
[viewAngle, dirVector, cameraPosition] = getCameraProperties(currentAxes);

stepSize = adjustStep(stepSize, currentAxes, dirVector);

if strcmp(currentAxes.Projection, 'perspective')
    camdolly(currentAxes, 0, 0, stepSize);
else
    newCamPosition = cameraPosition - stepSize * dirVector;
    currentAxes.CameraPosition = newCamPosition;
end

currentAxes.CameraViewAngle = viewAngle;

end