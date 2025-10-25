function ccaps=collisionCapsule(radius,height,pose,nvargs)
%collisionCapsule Create a collision capsule
%   CCAPS=collisionCapsule(RADIUS,HEIGHT,POSE) creates a struct which
%   represents a collision capsule of radius RADIUS and height HEIGHT units
%   in its local co-ordinate axes at the center of the capsule, and the
%   Z-axis of the local frame aligning with the HEIGHT dimension. POSE is
%   the homogeneous transformation matrix representing the position and
%   orientation of the frame of the capsule in the world. By default, POSE
%   is eye(4).
%
%   CCAPS=collisionCapsule(_,MaxNumVertices=NUMVERT) specifies the maximum
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
    ccaps=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(false,nvargs.MaxNumVertices);
    ccaps.m_Type=uint8(3);
    ccaps.m_Radius=radius;
    ccaps.m_Height=height;
    ccaps.m_Quaternion=robotics.core.internal.rotm2quat(pose(1:3,1:3));
    ccaps.m_Position=pose(1:3,4)';
end
