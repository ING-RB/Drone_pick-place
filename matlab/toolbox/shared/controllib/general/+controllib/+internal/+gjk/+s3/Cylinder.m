classdef Cylinder < controllib.internal.gjk.Base3d
    %CYLINDER Create a cylinder geometry.
    %
    %   CYL = Cylinder(RADIUS) creates a cylinder centered at origin.
    %
    %
    %   Cylinder properties:
    %       RADIUS      - Radius of the cylinder
    %       HEIGHT      - Height of the cylinder
    %       POSE        - Pose of the box relative to the world frame
    %
    %   Cylinder Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Cylinder.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Cylinder Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a Cylinder object for a cylinder with radius 1.
    %      cyl = controllib.internal.gjk.3d.Cylinder(1);
    %
    %      % Show cylinder primitive
    %      viewer3(cyl)
    %
	% 	See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %RADIUS Radius of the cylinder
        Radius

        %HEIGHT Radius of the cylinder
        Height
    end
    
    %% Private Properties
    properties (Access = private)
        %RInternal
        RInternal

        %HInternal
        HInternal
    end

	%% Constructor Method
    methods
        function obj = Cylinder(r,h)
            %CYLINDER Constructor.
            %   Pose of the collision geometry relative to the world
            %   frame. Default is eye(4)
            obj@controllib.internal.gjk.Base3d(eye(4,'like',r));

            obj.RInternal = r;
            obj.HInternal = h;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        function obj = set.Radius(obj,r)
            obj.RInternal = r;
        end
        function obj = set.Height(obj,h)
            obj.HInternal = h;
        end

        function r = get.Radius(obj)
            r = obj.RInternal;
        end
        function h = get.Height(obj)
            h = obj.HInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base3d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR

            v = obj.PInternal(1:3,1:3)'*v;

            R = obj.RInternal;
            H = obj.HInternal/2;

            delta = norm(v([1 2]));
            if delta > 0
                pc = [R*v(1:2)/delta; sign(v(3))*H; 1];
            else
                pc = [0;0;sign(v(3))*H;1];
            end

            temp = obj.Pose*pc;
            P = temp(1:3);
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj, varargin)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Cylinder.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)

            % Code is based of robotics.core.internal.PrimitiveMeshGenerator

            if nargin > 1
                N = varargin{1};
            else
                N = 32;
            end

            r = obj.RInternal;
            h = obj.HInternal;

            theta = linspace(0, 2*pi,N);
            theta = theta(1:end-1)';

            m = length(theta);

            % z-axis cylinder
            V = [r*cos(theta), r*sin(theta), -(h/2)*ones(m, 1); ... side
                 r*cos(theta), r*sin(theta),  (h/2)*ones(m, 1); ... side
                 0, 0, -h/2;    % bottom
                 0, 0, h/2]';   % cap

            F = [];% CCW
            for i = 1:m
                f= [i,   i+1,   m+i;    % side
                    m+i, i+1,   m+i+1;  % side
                    m+i, i+1+m, 2*m+2;  % cap
                    i,   1+2*m, i+1];   % bottom
                if i==m
                    f= [m,   1,     m+m;
                        m+m, 1,     m+1;
                        m+m, m+1,   m*2+2;
                        m,   m*2+1, 1];
                end
                F = [F; f ]; %#ok<AGROW>
            end
            F = [F(:,1), F(:,3), F(:,2)];

            %% Alternative 'Faces' matrix with different 'mesh' patterns
            % Alternative Code II to generate F matrix
            % F = [(1:N-1)' (2:N)' (N+2:2*N)' (N+1:2*N-1)'];
            %
            % Alternative Code III to generate F matrix
            % F =[hankel(1:N-1,[N-1 N]) (2*N+1)*ones(N-1,1);         ... % cap
            %     hankel(N+1:2*N-1,[2*N-1 2*N]) (2*N+2)*ones(N-1,1); ... % bottom
            %     hankel(1:N-1,[N-1 N]) (N+1:2*N-1)';                ... % side
            %     hankel(N+1:2*N-1,[2*N-1 2*N]) (2:N)']                  % side
        end
    end
end