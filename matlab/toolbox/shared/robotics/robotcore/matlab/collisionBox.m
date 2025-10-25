classdef collisionBox < robotics.core.internal.CollisionGeometryBase
%COLLISIONBOX Create a collision geometry as a box primitive
%   A box primitive is specified by its three side lengths. The box is
%   axis-aligned with its own body-fixed frame, whose origin is at the
%   box's center.
%
%   BOX = collisionBox(X, Y, Z) creates a box primitive with X, Y, Z as
%   its side lengths along the corresponding axes in the geometry-fixed
%   frame that is ready for collision checking. By default the
%   geometry-fixed frame collocates with the world frame.
%
%   BOX = collisionBox(_,Pose=POSE) sets Pose property of box to POSE,
%   relative to world frame. POSE is specified as either a 4-by-4
%   homogeneous transformation matrix or as an se3 object. By default, Pose
%   property is set to eye(4).
%
%   collisionBox properties:
%       X           - Side length of the box along x-axis
%       Y           - Side length of the box along y-axis
%       Z           - Side length of the box along z-axis
%       Pose        - Pose of the box relative to the world frame
%
%
%   collisionBox methods:
%       show                   - Plot box in MATLAB figure
%       convertToCollisionMesh - Convert a collision box to a collision
%                                mesh
%       fitCollisionCapsule    - Fit a collision capsule around a collision
%                                box
%
%   Example:
%
%      % Create a collision box object for a cube
%      cBox = collisionBox(1,1,1);
%
%      % Rotate the box in space
%      cBox.Pose = eul2tform([pi/4 pi/4 0]);
%
%      % Show the collision box
%      figure
%      show(cBox)
%
%   See also checkCollision, collisionCylinder, collisionCapsule,
%   collisionSphere, collisionMesh.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %X Side length of the box along x-axis of the geometry-fixed frame
        X

        %Y Side length of the box along y-axis of the geometry-fixed frame
        Y

        %Z Side length of the box along z-axis of the geometry-fixed frame
        Z
    end

    properties (Access = {?robotics.core.internal.InternalAccess})
        %XInternal
        XInternal

        %YInternal
        YInternal

        %ZInternal
        ZInternal
    end

    methods
        function obj = collisionBox(x, y, z, varargin)
        %COLLISIONBOX Constructor
            narginchk(3,5);

            validateattributes(x, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'X');
            validateattributes(y, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'Y');
            validateattributes(z, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'Z');
            obj@robotics.core.internal.CollisionGeometryBase(varargin{:});
            obj.XInternal = x;
            obj.YInternal = y;
            obj.ZInternal = z;
            obj.updateGeometry(x, y, z, true);

        end

    end

    methods
        function set.X(obj, x)
        %set.X
            validateattributes(x, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'X');
            obj.XInternal = x;
            obj.updateGeometry(x, obj.YInternal, obj.ZInternal);
        end

        function set.Y(obj, y)
        %set.Y
            validateattributes(y, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'Y');
            obj.YInternal = y;
            obj.updateGeometry(obj.XInternal, y, obj.ZInternal);
        end

        function set.Z(obj, z)
        %set.Z
            validateattributes(z, {'double'}, {'scalar', 'real', 'nonempty', ...
                                               'finite', 'nonnegative'}, 'collisionBox', 'Z');
            obj.ZInternal = z;
            obj.updateGeometry(obj.XInternal, obj.YInternal, z);
        end

        function x = get.X(obj)
        %get.X
            x = obj.XInternal;
        end

        function y = get.Y(obj)
        %get.Y
            y = obj.YInternal;
        end

        function z = get.Z(obj)
        %get.Z
            z = obj.ZInternal;
        end

        function newObj = copy(obj)
        %copy Creates a deep copy of the collision box object
            newObj = collisionBox(obj.XInternal, obj.YInternal, obj.ZInternal);
            newObj.Pose = obj.Pose;
        end

        function collMesh = convertToCollisionMesh(obj)
        %CONVERTTOCOLLISIONMESH Convert a collision box to a collision mesh
        %   COLLISIONMESH = convertToCollisionMesh(COLLISIONBOX) converts a
        %   box collision geometry, COLLISIONBOX, to a convex mesh
        %   collision geometry, COLLISIONMESH, which retains the pose of
        %   the COLLISIONBOX.
            collMesh = collisionMesh(obj.VisualMeshVertices);
            collMesh.Pose = obj.Pose;
        end

        function [collcap,fitInfo]=fitCollisionCapsule(obj)
        %FITCOLLISIONCAPSULE Fit a collision capsule around a collision box
        %   [COLLCAP,FITINFO]=fitCollisionCapsule(COLLBOX) fits a collision
        %   capsule COLLCAP around a collision box.  FITINFO is a struct with
        %   field "Residual" which contains the distance of every vertex of the
        %   COLLBOX from the central line of the capsule.
            fitInfo=struct("Residuals",zeros(8,1));
            [collcap,residual]=...
                robotics.core.internal.BoundingCapsuleGenerator.boundingCapsuleOfBox(...
                obj.X,obj.Y,obj.Z);
            collcap.Pose=obj.Pose*collcap.Pose;
            fitInfo.Residuals=residual;
        end

    end

    methods (Access = {?robotics.core.internal.InternalAccess})
        function updateGeometry(obj, x, y, z, initialize)
        %updateGeometry
            arguments
                obj
                x
                y
                z
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
                    robotics.core.internal.coder.CollisionGeometryBuildable.makeBox(x, y, z);
            else
                obj.GeometryInternal = robotics.core.internal.CollisionGeometry(x, y, z);
            end
            [F, V] = robotics.core.internal.PrimitiveMeshGenerator.boxMesh([x,y,z]);
            obj.VisualMeshVertices = V;
            obj.VisualMeshFaces = F;
            obj.EstimatedMaxReach = max([x, y, z]);
        end
    end

    methods(Static, Access = protected)
        function obj = loadobj(objFromMAT)
        %loadobj
            obj = objFromMAT;
            obj.GeometryInternal = ...
                robotics.core.internal.CollisionGeometry(obj.XInternal,...
                                                         obj.YInternal, ...
                                                         obj.ZInternal);
        end
    end
end
