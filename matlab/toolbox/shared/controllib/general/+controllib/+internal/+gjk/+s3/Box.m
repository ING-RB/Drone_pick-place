classdef Box < controllib.internal.gjk.Base3d
    %BOX Create a box geometry.
    %
    %   BOX = Box(W, H, D) creates a box primitive with W, H, D as
    %   its side lengths centered at origin.
    %
    %
    %   Box properties:
    %       WIDTH       - Side length of the rectangle along x-axis
    %       HEIGHT      - Side length of the rectangle along y-axis
    %       DEPTH       - Side length of the rectangle along z-axis
    %       POSE        - Pose of the box relative to the world frame
    %
    %   Box Private Method:
	%		<a href="matlab:help controllib.internal.gjk.3d.Box.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Box Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a box with sides 1.
    %      box = controllib.internal.gjk.3d.Box(1,1,1);
    %
    %      % Show box
    %      viewer3(box)
    %
	% 	See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %WIDTH Side length of the box along x-axis
        Width

        %HEIGHT Side length of the box along y-axis
        Height

        %DEPTH Side length of the box along y-axis
        Depth
    end
    
    %% Private Properties
    properties (Access = private)
        %WInternal
        WInternal

        %HInternal
        HInternal

        %DInternal
        DInternal

        %Hextent
        Hextent
    end

	%% Constructor Method
    methods
        function obj = Box(w, h, d)
            %BOX Constructor.
            %   Pose of the collision geometry relative to the world
            %   frame. Default is eye(4)
            InitPose = eye(4,'like',w);
            obj@controllib.internal.gjk.Base3d(InitPose);

            obj.WInternal = w;
            obj.HInternal = h;
            obj.DInternal = d;

            obj.Hextent = [w; h; d; 2*ones(1,'like',w)]/2;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        function obj = set.Width(obj, w)
            obj.WInternal = w;
        end

        function obj = set.Height(obj, h)
            obj.HInternal = h;
        end

        function obj = set.Depth(obj, d)
            obj.DInternal = d;
        end

        function w = get.Width(obj)
            w = obj.WInternal;
        end

        function h = get.Height(obj)
            h = obj.HInternal;
        end

        function d = get.Depth(obj)
            d = obj.DInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base3d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR
            %
            %   Let an axis-aligned box centered at point C: <cx,cy,vz> and
            %   extent vector: H = <w/2, h/2, d/2>. The support point for a
            %   direction v = <v1,v2,v3> is:
            % 
            %       sa(v) = C + sign(v).*H
            %             = C + <sign(v1)*w/2, sign(v2)*h/2, sign(v3)*d/2>
            %
            %   where sign(alpha) = {-1, alpha <0
            %                       { 0, otherwise
            %
            %   Last, as shown on theorem 4.6 [1], any object that has a
            %   proper support mapping, the following mapping can be uses
            %   as a support mapping under affine transformation T(x) =
            %   Bx+c. 
            %       sTa(v) = T(sa(B'v))
            %
            % [1] Van Den Bergen, G. (2003). Collision detection in
            % interactive 3D environments. CRC Press. pag 136137.
            
            ONE = ones(1,obj.DataType);
            
            % Note, B'v = (Bv')'. Then, it is better to find inverse of 3x1
            % matrix than a 3x3 matrix. 
            rdir = obj.PInternal(ONE+(0:2),ONE+(0:2))'*v;

            % Solve sign(B'v).*n
            % To avoid logical indexing: s(rdir<0) = -1. Use loop routine
            s = ones(4,1,obj.DataType);
            for i=ONE:3*ONE
                if rdir(i)<zeros(1,obj.DataType)
                    s(i) = -ONE;
                end
            end

            % Map B'v to function sa: 
            temp = obj.Pose*(s.*obj.Hextent);
            P = temp(ONE:3*ONE);
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

            wx = obj.WInternal/2;
            hy = obj.HInternal/2;
            dz = obj.DInternal/2;

            V = [wx, -hy, -dz;
                +wx,  hy, -dz;
                -wx,  hy, -dz;
                -wx, -hy, -dz;
                +wx, -hy,  dz;
                +wx,  hy,  dz;
                -wx,  hy,  dz;
                -wx, -hy,  dz]';

            F =[1 2 6;
                1 6 5;
                2 3 7;
                2 7 6;
                3 4 8;
                3 8 7;
                4 1 5;
                4 5 8;
                5 6 7;
                5 7 8;
                1 4 2;
                2 4 3];
        end
    end
end
