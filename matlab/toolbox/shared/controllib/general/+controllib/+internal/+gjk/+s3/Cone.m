classdef Cone < controllib.internal.gjk.Base3d
    %CONE Create a cone geometry.
    %
    %   CON = Cone(RADIUS, HEIGHT) creates a cone primitive with centered
    %   at origin.
    %
    %
    %   Cone properties:
    %       RADIUS      - Radius of the cone
    %       HEIGHT      - Height of the cone
    %       POSE        - Pose of the box relative to the world frame
    %
    %   Cone Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Cone.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Cone Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a cone
    %      con = controllib.internal.gjk.3d.Cone(1,2);
    %
    %      % Show circle primitive
    %      viewer3(con)
    %
	% 	See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %RADIUS Radius of the cone
        Radius

        %HEIGHT Radius of the cone
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
        function obj = Cone(r,h)
            %CONE Constructor.
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
            %
            % For more info, refer to Van Den Bergen, G. (2003). Collision
            % detection in interactive 3D environments. CRC Press. pag 136.

            R = obj.RInternal;
            H = obj.HInternal;

            v = obj.Pose(1:3,1:3)'*v;

            % From cross product definition (a x b)=|a||b|sin(theta)n, 
            % sin(theta) = (a x b)/|a|/|b|

            % Consider the following extent vectors at cone's reference
            % frame n1 = [R/2; -H; 0] and n2 = [R/2;  H; 0]
            % The LHS might be solved as >> cross(n1,n2)/norm(n1)/norm(n2).
            % To avoid cross products, use the computed analytical solution:
            sinth = (H*R)/(abs(H)^2 + abs(R)^2/4);

            % Spanned unit vector at central axis
            u = [0;0;1];
            % Component of v orthogonal to u 
            w = v - dot(u,v)*u;

            % Support Mapping of Cone
            if dot(u,v)/norm(v) >= sinth
                P = u*3*H/4;
            elseif norm(w) > eps(1)
                P = -u*H/4 + R*w./norm(w);
            else
                P = -u*H/4;
            end
            P = obj.Pose(1:3,1:3)*P + obj.Pose(1:3,end);
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj, varargin)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Cone.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)
            R = obj.RInternal;
            H = obj.HInternal;

            % Shape is divided in 2*(N-1) filled areas
            if nargin > 1
                N = varargin{1};
            else
                N = 10;
            end
            
            % Create XYZ points on the cone. Note that the first index of
            % <x,y,z> array contains the origin, followed by the cone apex
            % coordinate. The remaining array contains the coordinates
            % position for the base, a circle.
            theta = linspace(-.5,.5,N)*pi;
            x = [0 0 R*cos(theta) R*cos(theta+pi)];
            y = [0 0 R*sin(theta) R*sin(theta+pi)];
            z = [0 H zeros(1, 2*N)] - H/4;

            % Vertices 3xN 
            V = [x; y; z];

            % Since V(:,1) and V(:,2) correspond to the origin and the cone
            % apex coordinate, respectively, the connection matrix F might
            % use the following structure. 
            % For instance, when N == 3, matrix F corresponds to:
            %   F =[3 4 5 3 4 5;
            %       4 5 6 4 5 6;
            %       1 1 1 2 2 2]' 
            % For N, matrix F corresponds to:
            idx = ones(2*N-1,1);
            F =[cumsum(idx)+2 cumsum(idx)+3 idx;    % Face
                cumsum(idx)+2 cumsum(idx)+3 idx+1]; % Bottom
        end
    end
end