classdef Mesh < controllib.internal.gjk.Base3d
    %MESH Create a convex mesh geometry.
    %
    %   MSH = Mesh(VERTICES) creates a collision geometry as a
    %   convex mesh centered at origin.
    %
    %
    %   Mesh properties:
    %       VERTICES    - An N-by-3 matrix where N is the number of
    %                   vertices. Each row in Vertices represents the 
    %                   coordinates of a point in the 3D space. 
    %       Pose        - Pose of the box relative to the world frame
    %
    %   Mesh Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Mesh.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Mesh Private Method:
	%       GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %       % Create vertices matrix
    %       V = [1 1 -1; -1 1 -1; -1 -1 -1; 1 -1 -1; ...
    %           1 1  1; -1 1  1; -1  1  1; 1 -1  1];
    %
    %       % Create a convex mesh object
    %       msh = controllib.internal.gjk.3d.Mesh(V);
    %
    %       % Show convex mesh
    %       viewer3(msh)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">convex mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %VERTICES
        Vertices
    end

    properties (Access = public)
        %VInternal
        VInternal

        %N (todo: make private)
        N
    end

	%% Constructor Method
    methods
        function obj = Mesh(v)
            %MESH Constructor.
            %   Pose of the collision geometry relative to the world
            %   frame. Default is eye(4)
            obj@controllib.internal.gjk.Base3d(eye(4,'like',v));

            obj.VInternal = v;
            obj.N = size(v,1);
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        function obj = set.Vertices(obj,v)
            obj.VInternal = v;
        end
        function v = get.Vertices(obj)
            v = obj.VInternal;
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
            
            ONE = ones(1,obj.DataType);

            S = obj.Pose(ONE:3*ONE, ONE:3*ONE)*obj.VInternal' + ...
                obj.Pose(ONE:3*ONE, ONE*4);
            
            [~,i] = max(dot(repmat(v,ONE,obj.N),S));
            
            P = S(:,i);
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Box.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)
            
            V = obj.VInternal';
            F = convhull(cast(obj.VInternal,'double'));
        end
    end
end