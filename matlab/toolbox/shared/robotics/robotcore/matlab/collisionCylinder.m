classdef collisionCylinder < robotics.core.internal.CollisionGeometryBase
%COLLISIONCYLINDER Create a collision geometry as a cylinder primitive
%   A cylinder primitive is specified by the radius and the length. The
%   cylinder is axis-aligned with its own body-fixed frame (the side of
%   the cylinder lies along the z axis). The origin of the body-fixed
%   frame is at the cylinder's center.
%
%   CYL = collisionCylinder(RADIUS, LENGTH) creates a cylinder primitive
%   with radius RADIUS and length LENGTH that is ready for collision
%   checking. By default the geometry-fixed frame collocates with the
%   world frame.
%
%   CYL = collisionCylinder(_,Pose=POSE) sets Pose property of cylinder to
%   POSE, relative to world frame. POSE is specified as either a 4-by-4
%   homogeneous transformation matrix or as an se3 object. By default, Pose
%   property is set to eye(4).
%
%   collisionCylinder properties:
%       Radius      - Radius of the cylinder
%       Length      - Length of the cylinder
%       Pose        - Pose of the cylinder relative to the world frame
%
%   collisionCylinder methods:
%       show                   - Plot cylinder in MATLAB figure
%       convertToCollisionMesh - Convert a collision cylinder to a
%                                collision mesh
%       fitCollisionCapsule    - Fit a collision capsule around a collision
%                                cylinder
%   Example:
%
%      % Create a collision object for a cylinder
%      cCylinder = collisionCylinder(.2,1);
%
%      % Rotate the object in space
%      cCylinder.Pose = axang2tform([0 1 0 pi/2]);
%
%      % Show the collision object
%      figure
%      show(cCylinder)
%
%   See also checkCollision, collisionBox, collisionCapsule,
%   collisionSphere, collisionMesh.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %Radius The radius of the cylinder
        Radius

        %Length The length of the cylinder
        Length

    end

    properties (Access = {?robotics.core.internal.InternalAccess})
        %RadiusInternal
        RadiusInternal

        %Length
        LengthInternal
    end

    methods
        function obj = collisionCylinder(radius, length, varargin)
        %COLLISIONCYLINDER Constructor
            narginchk(2,4);

            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionCylinder', 'Radius');
            validateattributes(length, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'nonnegative'}, 'collisionCylinder', 'Length'); % can be zero
            obj@robotics.core.internal.CollisionGeometryBase(varargin{:});
            obj.RadiusInternal = radius;
            obj.LengthInternal = length;
            obj.updateGeometry(radius, length, true);
        end

        function set.Radius(obj, radius)
        %set.Radius
            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionCylinder', 'Radius');

            obj.RadiusInternal = radius;
            obj.updateGeometry(radius, obj.LengthInternal);
        end

        function set.Length(obj, length)
        %set.Length
            validateattributes(length, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'nonnegative'}, 'collisionCylinder', 'Length');

            obj.LengthInternal = length;
            obj.updateGeometry(obj.RadiusInternal, length);
        end

        function radius = get.Radius(obj)
        %get.Radius
            radius = obj.RadiusInternal;
        end

        function length = get.Length(obj)
        %get.Length
            length = obj.LengthInternal;
        end

        function newObj = copy(obj)
        %copy Creates a deep copy of the collision cylinder object
            newObj = collisionCylinder(obj.RadiusInternal, obj.LengthInternal);
            newObj.Pose = obj.Pose;
        end

        function collMesh = convertToCollisionMesh(obj)
        %CONVERTTOCOLLISIONMESH Convert a collision cylinder to a collision mesh
        %   COLLISIONMESH = convertToCollisionMesh(COLLISIONCYLINDER)
        %   converts a cylindrical collision geometry, COLLISIONCYLINDER,
        %   to a convex mesh collision geometry, COLLISIONMESH, which
        %   retains the pose of the COLLISIONCYLINDER.
            collMesh = collisionMesh(obj.VisualMeshVertices);
            collMesh.Pose = obj.Pose;
        end

        function [collcap,fitInfo]=fitCollisionCapsule(obj)
        %FITCOLLISIONCAPSULE Fit a collision capsule around a collision cylinder
        %   [COLLCAP,FITINFO]=fitCollisionCapsule(COLLCYLINDER) fits a
        %   collision capsule COLLCAP around a collision cylinder.  FITINFO
        %   is a struct with field "Residual" which is the maximum distance
        %   between every point of the curved surface of COLLCYLINDER and
        %   the central line of the capsule.
            fitInfo=struct("Residuals",0);
            [collcap,residual]=...
                robotics.core.internal.BoundingCapsuleGenerator.boundingCapsuleOfCylinder(...
                obj.Radius,obj.Length);
            collcap.Pose=obj.Pose*collcap.Pose;
            fitInfo.Residuals=residual;
        end
    end

    methods (Access = {?robotics.core.internal.InternalAccess})
        function updateGeometry(obj, radius, length, initialize)
        %updateGeometry
            arguments
                obj
                radius
                length
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
                    robotics.core.internal.coder.CollisionGeometryBuildable.makeCylinder(radius, length);
            else
                obj.GeometryInternal = robotics.core.internal.CollisionGeometry(radius, length);
            end
            [F, V] = robotics.core.internal.PrimitiveMeshGenerator.cylinderMesh([radius, length]);
            obj.VisualMeshVertices = V;
            obj.VisualMeshFaces = F;
            obj.EstimatedMaxReach = 2*max([radius, 0.5*length]);
        end
    end

    methods(Static, Access = protected)
        function obj = loadobj(objFromMAT)
        %loadobj

            obj = objFromMAT;
            obj.GeometryInternal = ...
                robotics.core.internal.CollisionGeometry(obj.RadiusInternal, ...
                                                         obj.LengthInternal);
        end
    end
end
