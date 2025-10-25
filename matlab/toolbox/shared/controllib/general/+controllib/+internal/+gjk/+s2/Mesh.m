classdef Mesh < controllib.internal.gjk.Base2d
    %MESH Create a convex mesh geometry.
    %
    %   MSH = Mesh(VERTICES) creates a collision geometry as a
    %   convex mesh centered at origin.
    %
    %
    %   Mesh properties:
    %       VERTICES    - An N-by-2 matrix where N is the number of
    %                   vertices. Each row in Vertices represents the 
    %                   coordinates of a point in the 3D space. 
    %       X           - Circle Position relative to origin x-axis 
    %       Y           - Circle Position relative to origin y-axis
    %       THETA       - Circle Orientation
    %
    %   MESH Private Method:
	%		<a href="matlab:help controllib.internal.gjk.2d.Mesh.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   MESH Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a convex mesh object
    %      msh = controllib.internal.gjk.2d.Mesh(...
    %           [1 1; -1 1; -1 -1; 1 -1]);
    %
    %      % Show convex mesh
    %      viewer2d(msh)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %VERTICES An N-by-2 matrix where N is the number of vertices. Each
        %row in Vertices represents the coordinates of a point in the 3D
        %space.
        Vertices
    end
    
    %% Private Properties
    properties (Access = private)
        %VInternal
        VInternal
    end

    properties (Access = private)
        %N
        N
    end

	%% Constructor Method
    methods
        function obj = Mesh(v)
            %MESH Constructor.
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            ZERO = zeros('like',v);
            obj@controllib.internal.gjk.Base2d(ZERO,ZERO,ZERO);

            obj.VInternal = v;
            obj.N = size(v,1);
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        %todo: Add 'validateattributes' for input arguments
        function obj = set.Vertices(obj,v)
            obj.VInternal = v;
        end
        function v = get.Vertices(obj)
            v = obj.VInternal;
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
            S = obj.Hr*obj.VInternal' + obj.Ht;
            [~,i] = max(dot(repmat(v,1,obj.N),S));
            P = S(:,i);
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. 
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)

            V = obj.VInternal';
            F = 1:size(obj.VInternal,1);
        end
    end
end