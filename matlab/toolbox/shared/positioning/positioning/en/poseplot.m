%POSEPLOT 3-D pose plot.
%   POSEPLOT plots the pose (position and orientation) at the parent axes 
%   origin with zero rotation.
%
%   POSEPLOT(Q) plots the pose specified by the quaternion Q. The
%   axes are set to the NED frame. 
%
%   POSEPLOT(R) plots the pose specified by the rotation matrix R.
%
%   POSEPLOT(..., POS) plots the pose with the position specified by the 
%   3-element vector POS.
%
%   POSEPLOT(..., F) plots the pose in the navigation frame specified by F.
%   F can be "ENU" or "NED" for the East-North-Up and North-East-Down
%   frames, respectively. The default value is "NED".
%
%   POSEPLOT(AX, ...) plots into the axes with handle AX.
%
%   POSEPLOT(..., Name=Value) specifies additional options for the
%   pose patch using one or more name-value pair arguments. Specify the
%   options after all other input arguments.    
%
%   H = POSEPLOT returns a handle to a PosePatch object.
%
%   Examples:
%       % Visualize quaternion.
%       q = quaternion([30 20 10],"eulerd","ZYX","frame");
%       poseplot(q)
% 
%       % Visualize rotation matrix.
%       R = rotmat(quaternion([4 52 9],"eulerd","ZYX","frame"),...
%           "frame");
%       poseplot(R)     
%
%       % Visualize pose between two quaternions.
%       q = quaternion([80 20 10; 20 2 5],"eulerd","ZYX","frame");
%       r = poseplot(q(1));
%       for t = 0:0.01:1
%           qs = slerp(q(1),q(2),t);
%           set(r,Orientation=qs);
%           drawnow
%       end
%
%   See also surf.

 
%   Copyright 2018-2021 The MathWorks, Inc.

