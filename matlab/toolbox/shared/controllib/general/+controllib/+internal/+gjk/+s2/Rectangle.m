classdef Rectangle < controllib.internal.gjk.Base2d
    %RECTANGLE Create a rectangle geometry.
    %
    %   REC = Rectangle(W, H) creates a rectangle primitive with W and H
    %   as its side lengths centered at origin.
    %
    %
    %   Rectangle properties:
    %       WIDTH       - Side length of the rectangle along x-axis
    %       HEIGHT      - Side length of the rectangle along y-axis
    %       X           - Rectangle Position relative to origin x-axis
    %       Y           - Rectangle Position relative to origin y-axis
    %       THETA       - Rectangle Orientation 
    %
    %   Rectangle Private Method:
	%		<a href="matlab:help controllib.internal.gjk.2d.Rectangle.supportFunction">supportFunction</a>	- Returns the farthest point in a direction DIR
	%
    %   Rectangle Private Method:
	%		GENERATEMESH	- Returns the vertex and face values
    %
    %
    %   Example:
    %
    %      % Create a primitive object for a square with sides 1.
    %      rec = controllib.internal.gjk.2d.Rectangle(1,1);
    %
    %      % Show rectangle primitive
    %      viewer2(rec)
    %
	%   See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %WIDTH Side length of the box along x-axis
        Width
        
        %HEIGHT Side length of the box along y-axis
        Height
    end
    
    %% Private Properties
    properties (Access = private)
        %WInternal
        WInternal

        %HInternal
        HInternal

        %Hextent
        Hextent
    end

	%% Constructor Method
    methods
        function obj = Rectangle(w, h)
            %RECTANGLE Constructor.
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            ZERO = zeros('like',w);
            obj@controllib.internal.gjk.Base2d(ZERO,ZERO,ZERO);

            obj.WInternal = w;
            obj.HInternal = h;
            obj.Hextent = [w; h]/2;
        end
    end

	%% Set and Get Methods for Dependent Properties
    methods
        %todo: Add 'validateattributes' for input arguments
        %   w: scalar, real, finite, positive
        %   h: scalar, real, finite, positive
        function obj = set.Width(obj,w)
            obj.WInternal = w;
            obj.Hextent = [w; obj.HInternal]/2;
        end
        function obj = set.Height(obj,h)
            obj.HInternal = h;
            obj.Hextent = [obj.WInternal; h]/2;
        end

        function w = get.Width(obj)
            w = obj.WInternal;
        end
        function h = get.Height(obj)
            h = obj.HInternal;
        end
    end

	%% Private Method only accessed by super
    methods (Access = {?controllib.internal.gjk.Base2d})
        function P = supportFunction(obj, v)
            %SUPPORTFUNCTION Returns the farthest point in a direction DIR
            %
            %  Let an axis-aligned box centered at point C: <cx,cy> and
            %  extent vector: H = <w/2, h/2>.
            % 
            %           (-w, h)/2       (w, h)/2
            %               o---------------o 
            %               |               | 
            %               |       x       | 
            %               |       (0,0)   |
            %               o---------------o
            %           (-w,-h)/2       (w,-h)/2
            %
            % The support point for a direction v = <v1,v2> is:
            % 
            %       sa(v) = C + sign(v).*H
            %             = C + <sign(v1)*w/2, sign(v2)*h/2>
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
            
            ONE  = ones(1,obj.DataType);

            % Note, B'v = (Bv')'. Then, it is better to find inverse of 3x1
            % matrix than a 3x3 matrix. 
            rdir = (v'*obj.Hr)';

            % Solve sign(B'v).*n
            % To avoid logical indexing: s(rdir<0) = -1. Use loop routine
            s = ones(2,1,obj.DataType);
            for i=ONE:2*ONE
                if rdir(i)<zeros(1,obj.DataType)
                    s(i) = -ONE;
                end
            end
            
            % Alternative
            % sFcnA = [obj.WInternal/2; obj.HInternal/2];
            % % sFcnA = obj.Hextent;
            % if rdir(1)<0
            %     sFcnA(1) = -1*sFcnA(1);
            % end
            % if rdir(2)<0
            %     sFcnA(2) = -1*sFcnA(2);
            % end
            
            % Map B'v to function sa: 
            %   sta(v) = T(sa(B'v))
            % P = obj.Hr*sFcnA + obj.Ht;
            P = obj.Hr*(s.*obj.Hextent) + obj.Ht;
        end
    end
	
    %% Public methods
    methods (Access = public) 
        function [V,F] = generateMesh(obj)
            %GENERATEMESH Returns the vertex values V and which vertices
            % to connect defined in F. The origin is at the center of the
            % Rectangle.
            %   Matrices V and F might be used for creating a patch.
            %   Example:
            %       >> patch('Vertices',V,'Faces',F)
            
            w = obj.Width;
            h = obj.Height;
            V =[w w -w -w; h -h -h h]/2;
            F = 1:4;
        end
    end
end