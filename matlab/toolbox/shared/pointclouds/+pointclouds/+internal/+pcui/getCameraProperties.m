function [viewAngle, dirVector, cameraPosition] = getCameraProperties(currentAxes)

viewAngle = currentAxes.CameraViewAngle;
cameraPosition = currentAxes.CameraPosition;
cameraTarget = currentAxes.CameraTarget;
dirVector = (cameraPosition - cameraTarget);

end
