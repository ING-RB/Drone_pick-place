function csph=collisionSphere(radius,pose,nvargs)
%collisionSphere Create a collision sphere
%   CSPH=collisionSphere(RADIUS,POSE) creates a struct which
%   represents a collision sphere of radius RADIUS units in its local
%   co-ordinate axes at the center of the sphere. POSE is the homogeneous
%   transformation matrix representing the position and orientation of the
%   frame of the sphere in the world. By default, POSE is eye(4).
%
%   CSPH=collisionSphere(_,MaxNumVertices=NUMVERT) specifies the maximum
%   number of vertices NUMVERT that can exist in a collision geometry struct for
%   homogenity of all collision geometry structs with the collision mesh
%   struct. By default, MaxNumVertices is 1e4.

%#codegen

%   Copyright 2024 The MathWorks, Inc.

    arguments
        radius
        pose=eye(4)
        nvargs.MaxNumVertices=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.DEFAULT_MAX_NUM_VERT
    end
    csph=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(false,nvargs.MaxNumVertices);
    csph.m_Type=uint8(2);
    csph.m_Radius=radius;
    csph.m_Quaternion=robotics.core.internal.rotm2quat(pose(1:3,1:3));
    csph.m_Position=pose(1:3,4)';
end
