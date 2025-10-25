function cmesh=collisionMesh(vert,pose,nvargs)
%collisionMesh Create a convex collision mesh
%   CMESH=collisionMesh(VERT,POSE) creates a struct which represents a
%   collision mesh specified by vertices VERT, which is an N-by-3 matrix,
%   in the mesh's local frame. POSE is the homogeneous transformation
%   matrix representing the position and orientation of the frame of the
%   mesh in the world. By default, POSE is eye(4).
%
%   CMESH=collisionMesh(_,MaxNumVertices=NUMVERT) specifies the maximum
%   number of vertices NUMVERT that can exist in a collision geometry struct for
%   homogenity of all collision geometry structs with the collision mesh
%   struct. By default, MaxNumVertices is 1e4.

%#codegen

%   Copyright 2024 The MathWorks, Inc.

    arguments
        vert
        pose=eye(4)
        nvargs.MaxNumVertices=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.DEFAULT_MAX_NUM_VERT
    end
    cmesh=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(false,nvargs.MaxNumVertices);
    cmesh.m_Type=uint8(4);
    cmesh.m_NumVertices=uint32(size(vert,1));
    vertflat=reshape(vert,1,[]);
    cmesh.m_Vertices(1:length(vertflat))=vertflat;
    cmesh.m_Quaternion=robotics.core.internal.rotm2quat(pose(1:3,1:3));
    cmesh.m_Position=pose(1:3,4)';
end
