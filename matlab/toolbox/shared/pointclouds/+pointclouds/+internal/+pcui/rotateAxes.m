function rotateAxes(currentAxes,dtheta,dphi,rotCenter,vertAxis,vertAxisDir)
% Rotate Axes around given axis

% Copyright 2018-2022 The MathWorks, Inc.

cameraPos = currentAxes.CameraPosition;
upVector = currentAxes.CameraUpVector;       

cameraTarget = currentAxes.CameraTarget;
aspectRatio = currentAxes.DataAspectRatio;

% View Axis: vector from camera position to rotation center
vaxis = rotCenter - cameraPos;

% Determine the index of the vertical axis.
coordsysval = strcmpi(vertAxis, ["x" "y" "z"]);

% First rotation axis is parallel to the principle up axis
raxis1 = [0 0 0];
if strncmpi(vertAxisDir,'down',1)
    raxis1(coordsysval) = -1;
    dtheta = -dtheta;
    dphi = -dphi;
else
    raxis1(coordsysval) = 1;
end

% Second rotation axis orthogonal to the plane made by raxis1 and vaxis
raxis2 = crossSimple(vaxis,raxis1);    
raxis2 = raxis2/simpleNorm(raxis2); 

upsidedown = (upVector(coordsysval) < 0);
if upsidedown
    dtheta = -dtheta;
    raxis2 = -raxis2;    
end

% Check if the camera up vector is parallel with the view direction;
% if yes, use another rotation axis
if any(isnan(raxis2))
    raxis2 = crossSimple(raxis1,upVector);
end

% Rotate the camera, its upvector, and the camera target around raxis1 and
% raxis2 by dtheta and dphi

rotateTwoAxis(cameraPos,cameraTarget,rotCenter,aspectRatio,upVector,...
    dtheta,dphi,raxis1,raxis2, currentAxes);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform camera rotation around 2 axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rotateTwoAxis(cameraPos,cameraTarget,rotCenter,aspectRatio,upVector,...
    dtheta,dphi,direction1,direction2, currentAxes)

[vectCamToRotCenter, upAxis, vectTargetToRotCenter, distCamToCenter, disTargToCenter] = calculateCameraVectors(cameraPos,cameraTarget,...
                                        rotCenter,aspectRatio,upVector);

horizontalAxis = direction1/simpleNorm(direction1);
verticalAxis = direction2/simpleNorm(direction2);

rotH = localRotMat(horizontalAxis,dtheta);
rotV = localRotMat(verticalAxis,-dphi);

rotHV = rotV * rotH;

[newCamPos,newUpVector,newCamTarget] = calculateCameraProperties(vectCamToRotCenter,...
    rotHV, upAxis, vectTargetToRotCenter, rotCenter, distCamToCenter, aspectRatio, disTargToCenter);

if ~all(isnan(newCamPos))    
    currentAxes.CameraPosition = newCamPos;
    currentAxes.CameraUpVector = newUpVector;
end

if ~all(isnan(newCamTarget))    
    currentAxes.CameraTarget = newCamTarget;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform camera rotation around third axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rotateThirdAxis(cameraPos,cameraTarget,rotCenter,aspectRatio,upVector,...
    dtheta,dphi,direction1,direction2, currentAxes)

rotationAxis = crossSimple(direction1,direction2);
rotationAxis = rotationAxis/simpleNorm(rotationAxis);

[vectCamToRotCenter, upAxis, vectTargetToRotCenter, distCamToCenter, disTargToCenter] = calculateCameraVectors(cameraPos,cameraTarget,...
                                        rotCenter,aspectRatio,upVector);

rotationAxis = rotationAxis/simpleNorm(rotationAxis);

currentAxes.Parent.CurrentPoint
if abs(dtheta) > abs(dphi)
    rotMat = localRotMat(rotationAxis,-dtheta);
else
    rotMat = localRotMat(rotationAxis,-dphi);
end

% rotH = localRotMat(rotationAxis,dtheta);
% rotV = localRotMat(rotationAxis,-dphi);
% 
% rotMat = rotV * rotH;

[newCamPos,newUpVector] = calculateCameraProperties(vectCamToRotCenter,...
    rotMat, upAxis, vectTargetToRotCenter, rotCenter, distCamToCenter, aspectRatio, disTargToCenter);

if ~all(isnan(newCamPos))    
    currentAxes.CameraUpVector = newUpVector;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate camera properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newCamPos,newUpVector,newCamTarget] = calculateCameraProperties(vectCamToRotCenter,...
    rotationMatrix, upAxis, vectTargetToRotCenter, rotCenter, distCamToCenter, aspectRatio, disTargToCenter)

newCamVector = -vectCamToRotCenter * rotationMatrix;
newUpAxis = upAxis * rotationMatrix;
newVTargVector = -vectTargetToRotCenter * rotationMatrix;

newCamPos = rotCenter + newCamVector * distCamToCenter.* aspectRatio;
newUpVector = newUpAxis.*aspectRatio;
newCamTarget = rotCenter + newVTargVector * disTargToCenter.*aspectRatio;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate camera vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vectCamToRotCenter, upAxis,...
    vectTargetToRotCenter, distCamToCenter, disTargToCenter] = calculateCameraVectors(cameraPos,cameraTarget,...
                                        rotCenter,aspectRatio,upVector)
% https://learnopengl.com/Getting-started/Camera
vectCamToRotCenter = (rotCenter-cameraPos)./aspectRatio;
rightAxis = crossSimple(vectCamToRotCenter, upVector./aspectRatio);
upAxis = crossSimple(rightAxis, vectCamToRotCenter);

distCamToCenter = simpleNorm(vectCamToRotCenter);
vectCamToRotCenter = vectCamToRotCenter/distCamToCenter;
upAxis = upAxis/simpleNorm(upAxis);

% same for target
vectTargetToRotCenter = (rotCenter-cameraTarget)./aspectRatio;
disTargToCenter = simpleNorm(vectTargetToRotCenter);
vectTargetToRotCenter = vectTargetToRotCenter/disTargToCenter;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotation matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rotM = localRotMat(axis,angle)
deg2rad = pi/180;
alph = angle*deg2rad;
cosa = cos(alph);
sina = sin(alph);
vera = 1 - cosa;
x = axis(1);
y = axis(2);
z = axis(3);
rotM = [cosa+x^2*vera x*y*vera-z*sina x*z*vera+y*sina; ...
  x*y*vera+z*sina cosa+y^2*vera y*z*vera-x*sina; ...
  x*z*vera-y*sina y*z*vera+x*sina cosa+z^2*vera]';

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simple cross product
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c=crossSimple(a,b)
c(1) = b(3)*a(2) - b(2)*a(3);
c(2) = b(1)*a(3) - b(3)*a(1);
c(3) = b(2)*a(1) - b(1)*a(2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simple norm for a 3D vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function n = simpleNorm(v)
n = sqrt(v(1)^2+v(2)^2+v(3)^2);
end
