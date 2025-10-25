classdef collisionMesh < robotics.core.internal.CollisionGeometryBase
%COLLISIONMESH Create a collision geometry as a convex mesh
%   A collision mesh is specified by a list of 3D vertices. The vertices
%   are specified in a geometry-fixed frame of the user's choice.
%
%   MSH = collisionMesh(VERTICES) creates a convex collision mesh MSH
%   from the list of VERTICES. By default the geometry-fixed frame
%   collocates with the world frame.
%
%   MSH = collisionMesh(_,Pose=POSE) sets Pose property of mesh to POSE,
%   relative to world frame. POSE is specified as either a 4-by-4
%   homogeneous transformation matrix or as an se3 object. By default, Pose
%   property is set to eye(4).
%
%   collisionMesh properties:
%       Vertices    - An N-by-3 matrix where N is the number
%                     of vertices. Each row in Vertices represents
%                     the coordinates of a point in the 3D space.
%                     Note that some of the points might be
%                     inside the constructed convex mesh.
%       Pose        - Pose of the mesh relative to the world frame
%
%
%   collisionMesh methods:
%       show                - plot the mesh in MATLAB figure
%       fitCollisionCapsule - Fit a collision capsule around a collision
%                             mesh
%
%   Example:
%
%      % Extract points from an existing STL file
%      stlFile = "groundvehicle.stl";
%      vehicleMesh = stlread(stlFile);
%      vertices = vehicleMesh.Points;
%
%      % View the base STL at the origin with lighting to show edges
%      figure
%      plotTransforms([0 0 0],[0 0 0 1],MeshFilePath=stlFile);
%      light
%
%      % Create a convex collision mesh from the STL using the
%      % STL vertices as the input
%      vehicleCollisionMesh = collisionMesh(vertices);
%
%      % View the collision mesh in a new figure
%      figure
%      show(vehicleCollisionMesh);
%
%   See also checkCollision, collisionBox, collisionCapsule,
%   collisionCylinder, collisionSphere.

%   Copyright 2019-2024 The MathWorks, Inc.
%#codegen

    properties (Dependent)
        %Vertices Vertices of the mesh
        Vertices
    end

    properties (Access = {?robotics.core.internal.InternalAccess})

        %VerticesInternal
        VerticesInternal
    end

    methods
        function obj = collisionMesh(vertices, varargin)
        %COLLISIONMESH Constructor
            narginchk(1,3);
            validateattributes(vertices, {'double'}, {'real', 'nonempty', 'ncols', 3, ...
                                                      'finite'}, 'collisionMesh', 'Vertices');
            obj@robotics.core.internal.CollisionGeometryBase(varargin{:});
            obj.VerticesInternal = vertices;
            obj.updateGeometry(vertices,true);

        end

        function set.Vertices(obj, vertices)
        %set.Vertices
            validateattributes(vertices, {'double'}, {'real', 'nonempty', 'ncols', 3, ...
                                                      'finite'}, 'collisionMesh', 'Vertices');

            obj.VerticesInternal = vertices;
            obj.updateGeometry(vertices);
        end

        function vertices = get.Vertices(obj)
        %get.Vertices
            vertices = obj.VerticesInternal;
        end

        function newObj = copy(obj)
        %copy Creates a deep copy of the collision mesh object
            newObj = collisionMesh(obj.VerticesInternal);
            newObj.Pose = obj.Pose;
        end

        function [collcap,fitInfo]=fitCollisionCapsule(obj)
        %FITCOLLISIONCAPSULE Fit a collision capsule around a collision mesh
        %   [COLLCAP,FITINFO]=fitCollisionCapsule(COLLMESH) fits a collision
        %   capsule COLLCAP around a collision mesh.  FITINFO is a struct with
        %   field "Residual" which contains the distance of every point of the
        %   COLLMESH from the central line of the capsule.
            fitInfo=struct("Residuals",zeros(size(obj.Vertices,1),1));
            [collcap,residuals]=...
                robotics.core.internal.BoundingCapsuleGenerator.boundingCapsuleOfMesh(...
                obj.Vertices);
            collcap.Pose=obj.Pose*collcap.Pose;
            fitInfo.Residuals=residuals;
        end

    end

    methods (Access = {?robotics.core.internal.InternalAccess})
        function updateGeometry(obj, vertices, initialize)
        %updateGeometry
            arguments
                obj
                vertices
                initialize=false
            end
            if(~coder.target('MATLAB'))
                % During code generation, when updating (i.e., not
                % initializing) the internal geometry, destroy the current
                % internal geometry and replace it with a new instance.
                if(~initialize)
                    robotics.core.internal.coder.CollisionGeometryBuildable.destructGeometry(obj.GeometryInternal);
                end
                obj.GeometryInternal = ...
                    robotics.core.internal.coder.CollisionGeometryBuildable.makeMesh(vertices, size(vertices, 1));
            else
                obj.GeometryInternal = robotics.core.internal.CollisionGeometry(vertices, size(vertices,1));
                try
                    F = convhull(vertices);
                    obj.VisualMeshVertices = vertices;
                    obj.VisualMeshFaces = F;
                catch
                    % only needed when fewer than 3 vertices are provided
                    if size(vertices, 1) == 1
                        obj.VisualMeshVertices = repmat(vertices, 3, 1);
                    elseif size(vertices, 1) == 2
                        obj.VisualMeshVertices = [vertices; vertices(2,:)];
                    else
                        obj.VisualMeshVertices = vertices;
                    end
                end
            end
            obj.EstimatedMaxReach = 2*max(max(vertices));

        end
    end

    methods(Static, Access = protected)
        function obj = loadobj(objFromMAT)
        %loadobj
            obj = objFromMAT;
            obj.GeometryInternal = robotics.core.internal.CollisionGeometry(obj.VerticesInternal, size(obj.VerticesInternal,1));
        end
    end
end
