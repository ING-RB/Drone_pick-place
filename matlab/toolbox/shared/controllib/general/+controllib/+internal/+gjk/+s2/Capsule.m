classdef Capsule < controllib.internal.gjk.Base2d
    %CAPSULE Create a capsule geometry.
    %
    %   CAP = Capsule(RADIUS) creates a capsule primitive with
    %   radius RADIUS and length distance between circles. Capsule is
    %   centered at origin.
    %
    %
    %   CAPSULE properties:
    %		RADIUS      - Radius of the semicircle end caps
    %       LENGTH      - Central rectangle length along x-axis
    %       X           - Circle Position relative to origin x-axis
    %       Y           - Circle Position relative to origin y-axis
    %       THETA       - Circle Orientation 
    %
    %   CAPSULE Private Method:
	%		<a href="matlab:help controllib.internal.gjk.2d.Capsule.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   CAPSULE Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a primitive object for a circle with radius 1.
    %      cap = controllib.internal.gjk.2d.Capsule(1,1);
    %
    %      % Show circle primitive
    %      viewer2(cap)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    
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
            ZERO = zeros('like',r);
            obj@controllib.internal.gjk.Base2d(ZERO,ZERO,ZERO);

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
    methods (Access = {?controllib.internal.gjk.Base2d})
		function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR.
			%	A capsule may be efficiently constructed by combining
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

            r = obj.RInternal;
            l = obj.LInternal;

            % Support mapping for centerd circle at origin
            sav = r*v./norm(v);

            % Rotates segment line: B'v 
            b = obj.Hr*[l;0];
            % Project transformed line to searching direction vector
            projLine = dot(-v, b);
            % Find if farthest point is the origin, extreme or halfway
            % point. 
            if abs(projLine) <= eps(1)%*dot(v,v)
                sbv = b/2;
            elseif projLine > 0
                sbv = b;
            else
                sbv = [0; 0];
            end

            % Find support for compound body and shift to capsules position
            P = sav - sbv + obj.Ht + b/2;
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

            R = obj.RInternal;
            L = obj.LInternal/2;

            N = 100; 
            angle1 = .5*linspace(-pi,pi,N);
            angle2 = .5*linspace(pi,3*pi,N);

            x = [R*cos(angle1)+L, R*cos(angle2)-L];
            y = [R*sin(angle1),   R*sin(angle2)];
            
            V = [x; y];
            F = 1:2*N;
        end
    end
end