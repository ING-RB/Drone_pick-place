classdef collisionSphere < robotics.core.internal.CollisionGeometryBase
%COLLISIONSPHERE Create a collision geometry as a sphere primitive
%   A sphere primitive is specified by its radius. The origin
%   of the geometry-fixed frame is at the sphere's center.
%
%   SPH = collisionSphere(RADIUS) creates a sphere primitive with radius
%   RADIUS that is ready for collision checking. By default the
%   geometry-fixed frame collocates with the world frame.
%
%   SPH = collisionSphere(_,Pose=POSE) sets Pose property of sphere to
%   POSE, relative to world frame. POSE is specified as either a 4-by-4
%   homogeneous transformation matrix or as an se3 object. By default, Pose
%   property is set to eye(4).
%
%   collisionSphere properties:
%       Radius      - Radius of the sphere
%       Pose        - Pose of the sphere relative to the world frame
%
%
%   collisionSphere methods:
%       show                   - plot sphere in MATLAB figure
%       convertToCollisionMesh - convert a collision sphere to a collision
%                                mesh
%       fitCollisionCapsule    - fit a collision capsule around a collision
%                                sphere
%
%   Example:
%
%      % Create a collision object for a sphere of radius 0.1
%      cSphere = collisionSphere(.1);
%
%      % Move the object in space
%      cSphere.Pose = trvec2tform([1 1 .5]);
%
%      % Show the collision object
%      figure
%      show(cSphere)
%
%   See also checkCollision, collisionBox, collisionCapsule,
%   collisionCylinder, collisionMesh.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %Radius Radius of the Sphere
        Radius
    end

    properties (Access = {?robotics.core.internal.InternalAccess})

        %RadiusInternal
        RadiusInternal
    end

    methods
        function obj = collisionSphere(radius, varargin)
        %COLLISIONSPHERE Constructor
            narginchk(1,3);

            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionSphere', 'radius');
            obj@robotics.core.internal.CollisionGeometryBase(varargin{:});
            obj.RadiusInternal = radius;
            obj.updateGeometry(radius,true);

        end

        function set.Radius(obj, radius)
        %set.Radius
            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionSphere', 'radius');
            obj.RadiusInternal = radius;
            obj.updateGeometry(radius);
        end

        function radius = get.Radius(obj)
        %get.Radius
            radius = obj.RadiusInternal;
        end

        function newObj = copy(obj)
        %copy Creates a deep copy of the collision sphere object
            newObj = collisionSphere(obj.RadiusInternal);
            newObj.Pose = obj.Pose;
        end

        function collMesh = convertToCollisionMesh(obj)
        %CONVERTTOCOLLISIONMESH Convert a collision sphere to a collision mesh
        %   COLLISIONMESH = convertToCollisionMesh(COLLISIONSPHERE)
        %   converts a spherical collision geometry, COLLISIONSPHERE, to a
        %   convex mesh collision geometry, COLLISIONMESH, which retains
        %   the pose of the COLLISIONSPHERE.
            collMesh = collisionMesh(obj.VisualMeshVertices);
            collMesh.Pose = obj.Pose;
        end

        function [collcap,fitInfo]=fitCollisionCapsule(obj)
        %FITCOLLISIONCAPSULE Fit a collision capsule around a collision sphere
        %   [COLLCAP,FITINFO]=fitCollisionCapsule(COLLSPHERE) fits a
        %   collision capsule COLLCAP around a collision sphere COLLSPHERE.
        %   FITINFO is a struct with field "Residuals" which is the sum of
        %   the distance between the origin of COLLSPHERE and the central
        %   line of the capsule, and its radius.
            fitInfo=struct("Residuals",0);
            [collcap,residual]=...
                robotics.core.internal.BoundingCapsuleGenerator.boundingCapsuleOfSphere(...
                obj.Radius);
            collcap.Pose=obj.Pose*collcap.Pose;
            fitInfo.Residuals=residual;
        end

    end

    methods (Access = {?robotics.core.internal.InternalAccess})
        function updateGeometry(obj, radius,initialize)
        %updateGeometry
            arguments
                obj
                radius
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
                    robotics.core.internal.coder.CollisionGeometryBuildable.makeSphere(radius);
            else
                obj.GeometryInternal = robotics.core.internal.CollisionGeometry(radius);
            end
            [F, V] = robotics.core.internal.PrimitiveMeshGenerator.sphereMesh(radius);
            obj.VisualMeshVertices = V;
            obj.VisualMeshFaces = F;
            obj.EstimatedMaxReach = 2*radius;
        end
    end

    methods(Static, Access = protected)
        function obj = loadobj(objFromMAT)
        %loadobj
            obj = objFromMAT;
            obj.GeometryInternal = ...
                robotics.core.internal.CollisionGeometry(obj.RadiusInternal);
        end
    end
end
