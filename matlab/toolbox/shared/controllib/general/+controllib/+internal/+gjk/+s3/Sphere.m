classdef Sphere < controllib.internal.gjk.Base3d
    %SPHERE Create a sphere geometry.
    %
    %   SPH = Sphere(RADIUS) creates a circle primitive with Sphere
    %   centered at origin.
    %
    %
    %   Sphere properties:
    %       RADIUS      - Radius of the sphere
    %       POSE        - Pose of the box relative to the world frame
    %
    %   Sphere Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Sphere.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Sphere Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create sphere with radius 1.
    %      sph = controllib.internal.gjk.3d.Sphere(1);
    %
    %      % Show Sphere
    %      viewer3(sph)
    %
	% 	See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %RADIUS Radius of the sphere
        Radius
    end
    
    %% Private Properties
    properties (Access = private)
        %RInternal
        RInternal
    end

	%% Constructor Method
    methods
        function obj = Sphere(r)
            %SPHERE Constructor.
            %   Pose of the collision geometry relative to the world
            %   frame. Default is eye(4)
            InitPose = eye(4,'like',r);
            obj@controllib.internal.gjk.Base3d(InitPose);

            obj.RInternal = r;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        function obj = set.Radius(obj,r)
            obj.RInternal = r;
        end
       
        function r = get.Radius(obj)
            r = obj.RInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base3d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR
            %   A support function of a convext object X as a function
            %   'sa(v)' is defined:  sa(v) is an element of X
            %
            %   such that
            %       dot(v,sa(v)) = max{dot(v,x): where 'x' is and element of 'X'}
            %
            %   A support function for a CIRCLE with radius R centered at
            %   point 'C' is
            %
            %       sa(v) = C + R*v/norm(v), if v~= 0 

            dirn = norm(v);
            if dirn~=0
                P = obj.RInternal*v/dirn + obj.PInternal(1:3,4);
            else
				% GJK routine will terminate routine when euclidean norm of 
				% searching direction is zero or approaching zero within small
				% range. 
				% However, we still return the center of sphere. 
				% todo: look to alternative solution.
                P = obj.PInternal(1:3,4);
            end
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj, varargin)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Box.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)

            R = obj.RInternal;

            if nargin > 1
                N = varargin{1};
            else
                N = 10;
            end

            th = (-N:2:N)/N*pi;
            ph = (-N:2:N)'/N*pi/2;
            cosph = cos(ph);        % cosphi(1) = 0; cosphi(n+1) = 0;
            sinth = sin(th);        % sintheta(1) = 0; sintheta(n+1) = 0;

            x = R*cosph*cos(th);
            y = R*cosph*sinth;
            z = R*sin(ph)*ones(1,N+1);

            V=[x(:) y(:) z(:)]';

            F = [];
            for i=1:N
                F = [F; 1+(i-1)*(N+1) 2+(i-1)*(N+1) 2+i*(N+1) 1+i*(N+1)];
                for j=1:N-1
                    F =[F; F(end,:)+1]; %#ok<AGROW>
                end
            end

        end
    end
end