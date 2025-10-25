classdef Circle < controllib.internal.gjk.Base2d
    %CIRCLE Create a circle geometry.
    %
    %   CIR = Circle(RADIUS) creates a circle primitive with
    %   radius RADIUS centered at origin.
    %
    %
    %   Circle properties:
    %       RADIUS      - Radius of the circle
    %       X           - Circle Position relative to origin x-axis
    %       Y           - Circle Position relative to origin y-axis
    %       THETA       - Circle Orientation 
    %
    %   CIRCLE Private Method:
	%		supportFunction	- Returns the farthest point in a direction DIR
	%
    %   CIRCLE Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a primitive object for a circle with radius 1.
    %      cir = controllib.internal.gjk.2d.Circle(1);
    %
    %      % Show circle primitive
    %      viewer2(cir)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %RADIUS Radius of the circle
        Radius
    end
    
    %% Private Properties
    properties (Access = private)
        %RInternal
        RInternal
    end

	%% Constructor Method
    methods
        function obj = Circle(r)
            %CIRCLE Constructor
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            ZERO = zeros('like',r);
            obj@controllib.internal.gjk.Base2d(ZERO,ZERO,ZERO);

            obj.RInternal = r;
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
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base2d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR.
            % A support function of a convext object X as a function
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
                P = obj.RInternal*v/dirn + obj.Ht;
            else
                % todo: verify this
                P = obj.Ht;
            end
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Circle.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)

            % Number of points to construct semicircles
            N = 100;
            % Set of angles
            angle = linspace(0,2*pi,N);
            % Find Vertices
            V = obj.RInternal*[cos(angle);sin(angle)];
            % Faces 
            F = 1:N;
        end
    end
end