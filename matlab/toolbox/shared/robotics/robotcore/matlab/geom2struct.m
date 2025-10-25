function S = geom2struct(geom,id,nv)
%geom2struct Converts collision geometry objects to struct-array
%
%   S = geom2struct(GEOM) takes in N-element cell-array of
%   collisionGeometry objects, GEOM, and converts them to N-element struct,
%   S, containing the following fields:
%
%           ID       : integer-valued scalar identifier.
%                       (Defaults to 1:N)
%           Vertices : Nx3 list of vertices w.r.t. the Pose frame
%           Faces    : Nx3 matrix where each row contains three indices
%                      corresponding to rows in the Vertices matrix forming
%                      a triangle
%           Pose     : The 4x4 transformation from the world frame to the
%                      frame in which the vertices are defined
%
%   S = geom2struct(GEOM,ID) optionally takes in an N-element
%   vector, ID, where each element of ID serves as a unique identifier
%   for the corresponding GEOM object.
%
%   S = geom2struct(___,Name=Value) optionally accepts the
%   followingNV-pairs:
%
%       LocalOffsetPose : a 4x4xN matrix, or N-element se3 of homogeneous 
%                         transformations such that the Nth transformation
%                         is applied directly to the Nth set of Vertices, 
%                         vBody. The world location of the vertices 
%                         becomes:
%
%                           vWorld = geom.Pose*LocalOffsetPose*vBody
%
%   Example:
%
%       % Construct scene using collision geometries
%       geom = {};
%       geom{end+1} = collisionBox(1, 1, 0.02);         % floor
%       geom{end}.Pose = trvec2tform([0,0,-.02]);
%       geom{end+1} = collisionBox(0.4,1,0.02);         % tabletop1
%       geom{end}.Pose = trvec2tform([0.3,0,0.6]);
%       geom{end+1} = collisionBox(0.6,0.2,0.02);       % tabletop2
%       geom{end}.Pose = trvec2tform([-0.2,0.4,0.5]);
%       geom{end+1} = collisionBox(0.02,0.02,1);        % post1
%       geom{end}.Pose = trvec2tform([.25,0.15,1]);
%       geom{end+1} = copy(geom{end});                  % post2
%       geom{end}.Pose = trvec2tform([.25,-0.15,1]);
%
%       % Extract the "meshes"
%       meshStruct1 = geom2struct(geom);
%
%       % Extract the "meshes" and provide custom identifiers
%       meshStruct2 = geom2struct(geom,(1:numel(geom))*5);
%
%       % Extract the "meshes" such that their vertices are all relative to
%       % the local frame of the first geometry
%       baseFrame = geom{1}.Pose;
%       offset(1:4,1:4,1) = baseFrame;
%       for i = 2:numel(geom)
%           offset(:,:,i) = baseFrame'*geom{i}.Pose;
%           geom{i}.Pose = baseFrame;
%       end
%       meshStruct3 = geom2struct(geom,LocalOffsetPose=offset);
%
%   See also collisionMesh

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    arguments
        %geom collisionGeometry objects
        geom (:,1) {mustBeA(geom,{'cell', 'robotics.core.internal.CollisionGeometryBase'})}

        %id Unique identifiers corresponding to each geometry
        id (:,1) {mustBeInteger, mustBePositive} = ones(0,1);

        %nv.LocalOffsetPose Homogeneous transform applied directly to vertices
        nv.LocalOffsetPose {mustBeA(nv.LocalOffsetPose,{'double','single','se3'})} = repmat(eye(4),1,1,0);
    end
    
    N = numel(geom);
    S = robotics.internal.meshStruct(N);
    if ~isempty(geom)
        formattedGeom   = formatGeom(geom);
        formattedID     = validateID(id,N);
        formattedTforms = validateTransforms(nv.LocalOffsetPose,N);
        for i = 1:N
            S(i,1).ID = formattedID(i);
            [S(i,1).Vertices, S(i,1).Faces] = mesh2FV(formattedGeom{i},formattedTforms(:,:,i));
            S(i,1).Pose = formattedGeom{i}.Pose;
        end
    end
end

function [vLocal,F] = mesh2FV(collisionGeom,localOffsetPose)
%mesh2FV Extract faces and vertices from collision geometry
    arguments
        collisionGeom (1,1) {mustBeA(collisionGeom,'robotics.core.internal.CollisionGeometryBase')}
        localOffsetPose (4,4)
    end
    if ~isa(collisionGeom,'collisionMesh')
        mesh = collisionGeom.convertToCollisionMesh();
    else
        mesh = collisionGeom;
    end
    vBody = mesh.Vertices;
    F = convhulln(vBody);

    % Apply the local transformation directly to the vertices. The world
    % location of the vertices is therefore:
    %   vWorld = mesh.Pose*vLocal
    vLocal = vBody*localOffsetPose(1:3,1:3)' + localOffsetPose(1:3,end)';
end

function geomArray = formatGeom(geom)
%formatGeom Wrap scalar collision geometry in cell-array for uniformity
    if iscell(geom)
        geomArray = geom;
    else
        geomArray = {geom};
    end
end

function ID = validateID(id,numGeom)
%validateID Validate or generate default identifiers

    % Assign to a new variable to support codegen
    if isempty(id)
        ID = 1:numGeom;
    else
        validateattributes(id,{'numeric'},{'numel',numGeom});
        ID = id;
    end
end

function tforms = validateTransforms(localOffsetPose,N)
%validateTransforms Validate or generate default transformations

    % Assign to a new variable to support codegen
    if isempty(localOffsetPose)
        tforms = repmat(eye(4),1,1,N);
    else
        if isa(localOffsetPose,'se3')
            % Convert se3 object to raw form
            tforms = localOffsetPose(:).tform;
        else
            tforms = localOffsetPose;
        end
        validateattributes(tforms,{'numeric'},{'size',[4 4 N]});
    end
end
