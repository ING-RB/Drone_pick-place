classdef collisionCapsule < robotics.core.internal.CollisionGeometryBase
%COLLISIONCAPSULE Create a collision geometry as a capsule primitive
%   A capsule primitive is specified by the radius and the length. The
%   capsule's central line segment aligns with its body z-axis. The origin
%   of the body-fixed frame is at the capsule's center.
%
%   CAP = collisionCapsule(RADIUS,LENGTH) creates a capsule primitive
%   with radius RADIUS and length LENGTH that is ready for collision
%   checking. By default the geometry-fixed frame co-locates with the
%   world frame.
%
%   CAP = collisionCapsule(_,Pose=POSE) sets Pose property of capsule to
%   POSE, relative to world frame. POSE is specified as either a 4-by-4
%   homogeneous transformation matrix or as an se3 object. By default, Pose
%   property is set to eye(4).
%
%   collisionCapsule properties:
%       Radius      - Radius of the capsule
%       Length      - Length of the capsule
%       Pose        - Pose of the capsule relative to the world frame
%
%   collisionCapsule methods:
%       show                   - Plot capsule in MATLAB figure
%       convertToCollisionMesh - Convert a collision capsule to a
%                                collision mesh
%
%   Example:
%
%      % Create a collision object for a capsule
%      cCapsule = collisionCapsule(.2,1);
%
%      % Rotate the object in space
%      cCapsule.Pose = axang2tform([0 1 0 pi/2]);
%
%      % Show the collision object
%      figure
%      show(cCapsule)
%
%   See also checkCollision, collisionBox, collisionSphere,
%   collisionCylinder collisionMesh.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        %Radius The radius of the capsule
        Radius

        %Length The length of the capsule
        Length
    end

    properties (Access = {?robotics.core.internal.InternalAccess})
        %RadiusInternal
        RadiusInternal

        %Length
        LengthInternal
    end

    properties(Constant,Hidden)
        %NUMCIRCLEPTS Number of points in the capsule's visual mesh
        NUMCIRCLEPTS=31;

        %IS2D Whether this capsule is a 2D capsule
        IS2D=false;
    end

    methods
        function obj = collisionCapsule(radius, length, varargin)
        %COLLISIONCAPSULE Constructor
            narginchk(2,4);

            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionCapsule', 'Radius');

            validateattributes(length, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'nonnegative'}, 'collisionCapsule', 'Length'); % can be zero
            obj@robotics.core.internal.CollisionGeometryBase(varargin{:});
            obj.RadiusInternal = radius;
            obj.LengthInternal = length;
            obj.updateGeometry(radius, length, true);
        end

        function set.Radius(obj, radius)
        %set.Radius
            validateattributes(radius, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'positive'}, 'collisionCapsule', 'Radius');

            obj.RadiusInternal = radius;
            obj.updateGeometry(radius, obj.LengthInternal);
        end

        function set.Length(obj, length)
        %set.Length
            validateattributes(length, {'double'}, {'scalar', 'real', 'nonempty', ...
                                                    'finite', 'nonnegative'}, 'collisionCapsule', 'Length');

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
        %copy Creates a deep copy of the collision capsule object
            newObj = collisionCapsule(obj.RadiusInternal, obj.LengthInternal);
            newObj.Pose = obj.Pose;
        end

        function collMesh = convertToCollisionMesh(obj)
        %CONVERTTOCOLLISIONMESH Convert a collision capsule to a collision mesh
        %   COLLISIONMESH = convertToCollisionMesh(COLLISIONCAPSULE)
        %   converts a cylindrical collision geometry, COLLISIONCAPSULE,
        %   to a convex mesh collision geometry, COLLISIONMESH, which
        %   retains the pose of the COLLISIONCAPSULE.
            collMesh = collisionMesh(obj.VisualMeshVertices);
            collMesh.Pose = obj.Pose;
        end

        function spheres=genspheres(obj,ratio)
        %GENSPHERES Generate spheres along the capsule's central line segment
        %   SPHERES=genspheres(caps,RATIO) Outputs a cell-array of collision
        %   spheres of type collisionSphere along the capsule's central
        %   line segment at specified ratio RATIO.  When RATIO is a row
        %   vector of size 1-by-N, SPHERES contains N number of collision
        %   spheres.
        %
        %   Example:
        %
        %   % Create a collision capsule
        %   cCapsule = collisionCapsule(2,10);
        %
        %   % Generate spheres at ratios 0.0, 0.5, and 1.0 of the
        %   % capsule length
        %   spheres=genspheres(cCapsule,linspace(0,1,3));
        %
        %   % Display the positions of each sphere
        %   for i = 1:length(spheres)
        %      disp(tform2trvec(spheres{i}.Pose))
        %   end
        %
        %   % show the capsule and set the face and edge alphas low
        %   [~,p]=show(cCapsule);
        %   p.FaceAlpha=0.2;
        %   p.EdgeAlpha=0.01;
        %   hold on;
        %
        %   % Show the generated spheres on the capsule
        %   cellfun(@show,spheres);
            spheres=repmat({collisionSphere(obj.Radius)},1,length(ratio));
            validateattributes(ratio,{'double'},{'vector','>=',0,'<=',1},'genspheres','ratio');
            for i = coder.unroll(1:length(ratio))
                spheres{i}=collisionSphere(obj.Radius);
                spheres{i}.Pose=obj.Pose*trvec2tform([0,0,ratio(i)*obj.Length-obj.Length/2]);
            end
        end

        function [isColliding,sepDist,witnessPts]=checkCollision(cap1,cap2)
        %CHECKCOLLISION Check collision between two capsules
        %   ISCOLLIDING = checkCollision(CAP1, CAP2) check if collision
        %   capsules CAP1 and CAP2 are in collision at their current poses,
        %   respectively. ISCOLLIDING is set to 1 if collision happens and 0 if
        %   no collision is found.
        %
        %   [ISCOLLIDING, SEPDIST, WITNESSPTS] = checkCollision(___) returns
        %   additional information related to the collision check in SEPDIST
        %   and  WITNESSPTS. If no collision is detected, SEPDIST represents
        %   the minimal distance between two geometries and WITNESSPTS
        %   represents the witness points on each geometry as a 3-by-2 matrix,
        %   where each column is a 3-D witness point. The line segment that
        %   connects the two witness points realizes the minimal distance, or
        %   the separation distance. When CAP1 and CAP2 are in collision,
        %   SEPDIST is set to nan, and WITNESSPTS are set to nan(3,2).
            validateattributes(cap2, {'robotics.core.internal.CollisionGeometryBase'}, ...
                               {'scalar', 'nonempty'}, 'checkCollision', 'cap2');
            if(~isa(cap2,'collisionCapsule'))
                [isColliding,sepDist,witnessPts]=robotics.core.internal.checkCollision(cap1,cap2);
            else
                p1_=cap1.Pose*trvec2tform([0,0,-cap1.Length/2]);
                p1=p1_(1:3,end);
                v1=cap1.Pose(1:3,3);
                D1=cap1.Length;
                R1=cap1.Radius;
                p2_=cap2.Pose*trvec2tform([0,0,-cap2.Length/2]);
                p2=p2_(1:3,end);
                v2=cap2.Pose(1:3,3);
                D2=cap2.Length;
                R2=cap2.Radius;
                [isColliding_,sepDist,witnessPts_]=robotics.core.internal.checkCollisionCapsuleWrapper(p1,v1,D1,R1,...
                                                                                                       p2,v2,D2,R2,...
                                                                                                       false);
                isColliding=double(isColliding_);
                witnessPts=squeeze(witnessPts_);
            end
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
                    robotics.core.internal.coder.CollisionGeometryBuildable.makeCapsule(radius, length);
            else
                obj.GeometryInternal = robotics.core.internal.CollisionGeometry(radius, length);
                obj.GeometryInternal.setType("Capsule");
            end
            [F, V_]=...
                robotics.core.internal.PrimitiveMeshGenerator.capsuleMesh(length,...
                                                                          radius,...
                                                                          obj.NUMCIRCLEPTS,...
                                                                          obj.IS2D);

            % The vertices that are returned by the capsuleMesh assume a
            % different local frame for the capsule. The frame is offset by the
            % following fixed transform.
            tform=[ [0,  1,  0, 0];
                    [0,  0,  1, 0];
                    [1,  0,  0, -length/2]
                    [0,  0,  0, 1]];
            obj.VisualMeshVertices = V_*tform(1:3,1:3)'+tform(1:3,end)';
            obj.VisualMeshFaces = F;
            obj.EstimatedMaxReach = radius+(length/2);
        end
    end

    methods(Static, Access = protected)
        function obj = loadobj(objFromMAT)
        %loadobj
            obj = objFromMAT;
            obj.GeometryInternal = ...
                robotics.core.internal.CollisionGeometry(obj.RadiusInternal, ...
                                                         obj.LengthInternal);
            obj.GeometryInternal.setType("Capsule");
        end
    end
end
