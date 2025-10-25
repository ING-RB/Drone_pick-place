classdef Triangle < controllib.internal.gjk.Base2d
    %TRIANGLE Create a triangle geometry.
    %
    %   TRI = Triangle(B, H) creates a triangle primitive base
    %   length BASE and height length HEIGHT centered at origin.
    %
    %
    %   primitiveRectangle properties:
    %       BASE        - Base length of the triangle along x-axis
    %       HEIGHT      - Height of the triangle along y-axis
    %       X           - Triangle Position relative to origin x-axis
    %       Y           - Triangle Position relative to origin y-axis
    %       THETA       - Triangle Orientation 
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
    %       % Create a primitive object for a triangle with base length 1
    %       %and height 1. 
    %       tri = controllib.internal.gjk.2d.Triangle(1,1);
    %
    %      % Show triangle primitive
    %      viewer2(tri)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %BASE Base length of the triangle along x-axis
        Base

        %HEIGHT Height of the triangle along y-axis
        Height
    end
    
    %% Private Properties
    properties (Access = private)
        %BInternal
        BInternal

        %HInternal
        HInternal
    end

	%% Constructor Method
    methods
        function obj = Triangle(b, h)
            %TRIANGLE Constructor.
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            ZERO = zeros('like',b);
            obj@controllib.internal.gjk.Base2d(ZERO,ZERO,ZERO);

            obj.BInternal = b;
            obj.HInternal = h;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        %todo: Add 'validateattributes' for input arguments
        function obj = set.Base(obj,b)
            obj.BInternal = b;
        end
        function obj = set.Height(obj,h)
            obj.HInternal = h;
        end

        function b = get.Base(obj)
            b = obj.BInternal;
        end
        function h = get.Height(obj)
            h = obj.HInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base2d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR
            %   A support function of a convext object X as a function
            %   'sa(v)' is defined:  sa(v) is an element of X
            %
            %   such that
            %       dot(v,sa(v)) = max{dot(v,x): where 'x' is and element of 'X'}
            %
            %   There is an alternative support mapping for cone and
            %   triangles in 'Bergen pg. 136'. Preliminary tests did not
            %   show substancial advantage for triangles shapes. 
            %   For now, it uses max{dot(v,x)}, where x is 2x3.
            
            % Form triangle vertices
            b = obj.BInternal/2;
            h = obj.HInternal/2;
            V = [-b b 0; -h -h h];
            
            % Find vertices location by applying transformation T(x)=B(x)+c
            S = obj.Hr*V + obj.Ht;
            
            % Find x for max{dot(v,x)}
            [~,i] = max(dot(repmat(v,1,3),S));
            P = S(:,i);
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Triangle.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)

            b = obj.BInternal;
            h = obj.HInternal;

            V = [-b b 0; -h -h h]/2;
            F = 1:3;
        end
    end
end