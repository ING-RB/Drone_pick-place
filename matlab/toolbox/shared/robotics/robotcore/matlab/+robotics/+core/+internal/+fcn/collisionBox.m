function cbox=collisionBox(x,y,z,pose,nvargs)
%collisionBox Create a collision box
%   CBOX=collisionBox(X,Y,Z,POSE) creates a struct which represents a
%   collision box of size X, Y, and Z units respectively in its local
%   co-ordinate axes at the center of the box. POSE is the homogeneous
%   transformation matrix representing the position and orientation of the
%   frame of the box in the world. By default, POSE is eye(4).
%
%   CBOX=collisionBox(_,MaxNumVertices=NUMVERT) specifies the maximum
%   number of vertices NUMVERT that can exist in a collision geometry struct for
%   homogenity of all collision geometry structs with the collision mesh
%   struct. By default, MaxNumVertices is 1e4.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        x
        y
        z
        pose=eye(4)
        nvargs.MaxNumVertices=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.DEFAULT_MAX_NUM_VERT
    end
    cbox=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(false,nvargs.MaxNumVertices);
    cbox.m_Type=uint8(0);
    cbox.m_X=x;
    cbox.m_Y=y;
    cbox.m_Z=z;
    cbox.m_Quaternion=robotics.core.internal.rotm2quat(pose(1:3,1:3));
    cbox.m_Position=pose(1:3,4)';
end
