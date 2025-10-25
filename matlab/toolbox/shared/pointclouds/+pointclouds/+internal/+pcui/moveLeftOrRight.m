function moveLeftOrRight(stepSize, currentAxes)

import pointclouds.internal.pcui.*
[viewAngle, dirVector] = getCameraProperties(currentAxes);

stepSize = adjustStep(stepSize, currentAxes, dirVector);

camdolly(currentAxes, stepSize,0,0);

currentAxes.CameraViewAngle = viewAngle;

end