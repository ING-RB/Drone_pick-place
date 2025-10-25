classdef Capsule < controllib.internal.gjk.Base3d
    %CAPSULE Create a collision geometry as a circle primitive.
    %
    %   CAP = Capsule(RADIUS) creates a capsule primitive with
    %   radius RADIUS and length distance between circles. Capsule is
    %   centered at origin.
    %
    %
    %   Capsule properties:
    %       RADIUS      - Radius of the semi sphere end caps
    %       LENGTH      - Central cylinder length along x-axis
    %       POSE        - Pose of the box relative to the world frame
    %
    %   Capsule Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Capsule.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Capsule Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a primitive object for a circle with radius 1.
    %      cap = controllib.internal.gjk.3d.Capsule(1,1);
    %
    %      % Show circle primitive
    %      viewer3(cap)
    %
	% 	See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %RADIUS Radius of the semicircle end caps
        Radius

        %LENGTH Central rectangle length along x-axis
        Length
    end
    
    %% Private Properties
    properties (Access = private)
        %RInternal
        RInternal

        %LInternal
        LInternal
    end

	%% Constructor Method
    methods
        function obj = Capsule(r,l)
            %PRIMITIVECAPSULE Constructor
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            obj@controllib.internal.gjk.Base3d(eye(4,'like',r));

            obj.RInternal = r;
            obj.LInternal = l;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        %todo: Add 'validateattributes' for input arguments
        function obj = set.Radius(obj,r)
            obj.RInternal = r;
        end
        function r = get.Radius(obj)
            r = obj.RInternal;
        end

        function obj = set.Length(obj,l)
            obj.LInternal = l;
        end
        function l = get.Length(obj)
            l = obj.LInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base3d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR
			%
			%   A capsule may be efficiently constructed by combining
			%	a circle and line, and applying the Minkowski difference:
			%		K = C-L = {k: k+L pertence C}
            %
			%	where:  C is a set of points of a circle
            %           L a set of points of a line. 
            %           K is defined as a compound object, which in this
            %             case, is a capsule.
			%
			%   The support mapping of any compound body is readily
			%   provided by [1]:
            %       sk(v) = sc(v)-sl(-v) 
            %
            %   Note a support mapping for a CIRCLE with radius R centered
            %   at point 'C' is [2]
            %       sa(v) = C + R*v/norm(v), if v~= 0 
            %
            %   Also, a support mapping for a segment line with an extreme
            %   at origin is found by finding the projection of searching
            %   direction vector:
            %
            %       sb(v) = extreme point,  if dot(L,v) > 0
            %       sb(v) = halfway point,  if dot(L,v) = 0
            %       sb(v) = origin,         if dot(L,v) < 0
            %
            %   Last, as shown on theorem 4.6 [2], any object that has a
            %   proper support mapping, the following mapping can be uses
            %   as a support mapping under affine transformation T(x) =
            %   Bx+c. 
            %       sTa(v) = T(sa(B'v))
            %
            % [1] Mattia Montanari, PhD Thesis: "New distance algorithms 
            % for optimisation and contact mechanics problems". pag. 14
            % [2] Van Den Bergen, G. (2003). Collision detection in
            % interactive 3D environments. CRC Press. pag 136137.

            R = obj.RInternal;
            L = obj.LInternal;

            % Support mapping for centerd circle at origin
            sav = R*v./norm(v);

            % Rotates segment line: B'v 
            b = obj.Pose(1:3,1:3)*[0;0;L];
            % Project transformed line to searching direction vector
            projLine = dot(-v, b);
            % Find if farthest point is the origin, extreme or halfway
            % point. 
            if abs(projLine) <= eps(1)
                sbv = b/2;
            elseif projLine > 0
                sbv = b;
            else
                sbv = [0; 0; 0];
            end
            
            % Find support for compound body and shift to capsules position
            P = sav - sbv + obj.Pose(1:3,4) + b/2;
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Capsule.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)
            
            % *Based of robotics.core.internal.PrimitiveMeshGenerator

            R = obj.RInternal;
            L = obj.LInternal/2;

            p = 9;
            % p = 31;

            % Number of "rings" along the hemisphere's x-axis
            numRings = 6;
            % numRings = 12;

            % Number of points in each ring
            pTot = 1+2*p;

            % Create xyz points on hemisphere
            th = linspace(0,pi/2,numRings);
            ph = linspace(2*pi,0,pTot)';
            x = ones(pTot,1)*sin(th)*R;
            y = cos(ph)*cos(th)*R;
            z = sin(ph)*cos(th)*R;

            % Number of vertices in hemisphere
            nS = numel(x);

            % Combine top/bottom vertices to form ends of capsule
            V = [x(:)+L, y(:), z(:); -x(:)-L, y(:), z(:)]';
            V = [0, 1, 0; 0 0 1; 1 0 0]*V;

            % Define faces for hemisphere. All vertices aside from those in
            % the ring furthest from sphere-center serve as the first
            % vertex in a 4-edge face. Therefore the collection of all
            % faces in the sphere can be formed by joining each of these
            % vertices (FSphere1) with its direct neighbor and those in the
            % proceeding ring, [0, 1, pTot+1, pTot].
            FSphere1 = (1:(nS-pTot-1))';
            FSphere = FSphere1+[0,1,pTot+1,pTot];

            % Define faces for cylinder. Cylinder faces can be formed by
            % connecting each point on the first hemisphere's equator,
            % FCylinder1, with its immediate neighbor and the equatorial
            % points of the opposing hemisphere, [0,1,nS+1,nS].
            FCylinder1 = (1:(pTot-1))';
            FCylinder = FCylinder1+[0,1,nS+1,nS];

            % Represent final patch using faces
            F = [FSphere;FSphere+nS;FCylinder];

        end
    end
end