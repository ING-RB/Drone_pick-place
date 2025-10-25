function ccyl=collisionCylinder(radius,height,pose,nvargs)
%collisionCylinder Create a collision cylinder
%   CCYL=collisionCylinder(RADIUS,HEIGHT,POSE) creates a struct which
%   represents a collision cylinder of radius RADIUS and height HEIGHT
%   units in its local co-ordinate axes at the center of the cylinder, and
%   the Z-axis of the local frame aligning with the HEIGHT dimension. POSE
%   is the homogeneous transformation matrix representing the position and
%   orientation of the frame of the cylinder in the world. By default, POSE
%   is eye(4).
%
%   CCYL=collisionCylinder(_,MaxNumVertices=NUMVERT) specifies the maximum
%   number of vertices NUMVERT that can exist in a collision geometry struct for
%   homogenity of all collision geometry structs with the collision mesh
%   struct. By default, MaxNumVertices is 1e4.

%#codegen

%   Copyright 2024 The MathWorks, Inc.

    arguments
        radius
        height
        pose=eye(4)
        nvargs.MaxNumVertices=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.DEFAULT_MAX_NUM_VERT
    end
    ccyl=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(false,nvargs.MaxNumVertices);
    ccyl.m_Type=uint8(1);
    ccyl.m_Radius=radius;
    ccyl.m_Height=height;
    ccyl.m_Quaternion=robotics.core.internal.rotm2quat(pose(1:3,1:3));
    ccyl.m_Position=pose(1:3,4)';
end
