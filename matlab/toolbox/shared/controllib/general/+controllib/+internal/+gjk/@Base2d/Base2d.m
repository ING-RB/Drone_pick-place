classdef Base2d < controllib.internal.gjk.GJK
    %PRIMITIVEBASE2D Base class for 2D geometries
    % 
    % PRIMITIVEBASE2D Public Properties (Dependent):
    %   <a href="matlab:help controllib.internal.gjk.Base2d.X">X</a>				Position relative to origin x-axis.
    %   <a href="matlab:help controllib.internal.gjk.Base2d.Y">Y</a>				Position relative to origin y-axis.
    %   <a href="matlab:help controllib.internal.gjk.Base2d.Theta">Theta</a>   		Angular displacement in the xy plane counterclockwise (rad).
    %
    % PRIMITIVEBASE2D Private Properties:
    %   <a href="matlab:help controllib.internal.gjk.Base2d.YInternal">XInternal</a>   	Stored value of <a href="matlab:help controllib.internal.gjk.Base2d.X">X</a>
    %   <a href="matlab:help controllib.internal.gjk.Base2d.YInternal">YInternal</a>   	Stored value of <a href="matlab:help controllib.internal.gjk.Base2d.Y">Y</a>
    %   <a href="matlab:help controllib.internal.gjk.Base2d.YInternal">TInternal</a>   	Stored value of <a href="matlab:help controllib.internal.gjk.Base2d.Theta">Theta</a>
    %
    % PRIMITIVEBASE2D Protected Properties:
    %   <a href="matlab:help controllib.internal.gjk.Base2d.Hr">Hr</a>				Extracted Rotation Matrix of shape.
    %   <a href="matlab:help controllib.internal.gjk.Base2d.Ht">Ht</a>				Extracted Translation Matrix of shape.
    %
    % PRIMITIVEBASE2D Public Methods:
    %   <a href="matlab:help controllib.internal.gjk.Base2d.supportMapping">supportMapping</a>	Calculates the Minkowski difference between two convex shapes.
    %   <a href="matlab:help controllib.internal.gjk.Base2d.updateHr">updateHr</a>	 	Update Rotation matrix
    %   <a href="matlab:help controllib.internal.gjk.Base2d.updateHt">updateHt</a>		Update Translation matrix
    %   <a href="matlab:help controllib.internal.gjk.Base2d.cross2d">cross2d</a>			Returns the norm cross product of the vectors A anb B.
    %   <a href="matlab:help controllib.internal.gjk.Base2d.tripleProd">tripleProd</a>		Returns the triple cross product: (AxB)xC. 
    %
	% PRIMITIVEBASE2D Protected Methods (static)
    %   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex1">testSimplex1</a>	Routine for line simplex
    %   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex2">testSimplex2</a>	Routine for triangle simplex
    %   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex3">testSimplex3</a>	Routine for tetrahedron simplex
	% 
	% PRIMITIVEBASE2D Public Methods (abstract)
	%   <a href="matlab:help controllib.internal.gjk.Base2d.checkCollision">checkCollision</a>	GJK implements the Gilbert-Johnson-Keerthi collision detection algorithm (Main routine)
	%   <a href="matlab:help controllib.internal.gjk.Base2d.generateMesh">generateMesh</a>	Returns the vertex and face values
    %
	% See also <a href="matlab:help controllib.internal.gjk.2d.Rectangle">rectangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Circle">circle</a>, <a href="matlab:help controllib.internal.gjk.2d.Triangle">triangle</a>, <a href="matlab:help controllib.internal.gjk.2d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.2d.Mesh">convex mesh</a>.
    %
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.

    %% Dependent Properties
    properties (Dependent)
        %THETA Orientation
        %
        %   Default: 0
        Theta

        %X Position relative to origin x-axis
        %
        %   Default: 0
        X

        %Y Position relative to origin y-axis
        %
        %   Default: 0
        Y
    end    
    %% Private Properties
    properties (Access = private)
        % TInternal
        TInternal

        % XInternal
        XInternal
        
        % YInternal
        YInternal
    end
    %% Protected Properties
    properties (Access = protected)
        %Hr Extracted Rotation Matrix from pose P: Hr=Pose(1:3,1:3)
        Hr

        %Ht Extracted Position Array from pose P: Ht=Pose(1:3,4)
        Ht
    end
    %% Public Methods
    methods
        function obj = Base2d(x, y, theta)
            %PRIMITIVEBASE2D Constructor
            %   Pose of the collision geometry relative to the world frame.
            %   It is initialized at origin (0,0) and orientation as 0
            %   rad. Position X and Y, and Orientation Theta can be updated
            %   after you create the primitive geometry.
            obj@controllib.internal.gjk.GJK();

            % Position and Orientation
            obj.XInternal = x;
            obj.YInternal = y;
            obj.TInternal = theta;

            % Set Translation Matrix
            obj.Ht = [obj.XInternal; obj.YInternal];
            
            % Set Rotatation Matrix
            obj = obj.updateHr(obj.TInternal);

            obj.DataType = class(x);
            
            obj.Is2D = true;
        end
        function obj = updateHr(obj, theta)
            %UPDATEHR Update Rotation matrix
            %   Rotation Matrix is a 2x2 transformation matrix to rotate
            %   shape in the xy plane counterclockwise through an angle
            %   THETA with respect to the positive x axis about the origin
            %   in the xy plane counterclockwise. 
            %   For a given angle theta,
            %       R = [cos(theta) -sin(theta); cos(theta)  sin(theta)]

            %   points in the xy plane counterclockwise. For a given angle
            %   theta, R = [cos(theta) -sin(theta); cos(theta)  sin(theta)]
            ct = cos(theta);
            st = sin(theta);
            obj.Hr = [ct -st; st ct];
        end
        function obj = updateHt(obj, x, y)
            %UPDATEHT Update Translation matrix
            obj.Ht = [x; y];
        end
    end

    methods (Static,Access=public)
        %CHECKCOLLISION GJK implements the Gilbert-Johnson-Keerthi collision
        %detection algorithm (Main routine)
        [collisionStatus,sepdist,witnesspts,out] = checkCollision(geom1, geom2, opt);
    end

    methods (Abstract=true,Access=public)
        %GENERATEMESH  Returns the vertex values V and which vertices to
        %connect defined in F. It is a helper method for plots. It is not
        %used in the main GJK algorithm. 
		%   Example:
		%		>> [V,F] = generateMesh(obj)
        %       >> patch('Vertices',V,'Faces',F)
        [V,F] = generateMesh(obj);
    end
    
    %% Set and Get Methods for Dependent Properties
    methods
        function obj = set.X(obj,x)
            %set.X
            obj.XInternal = x;
            obj = obj.updateHt(obj.XInternal, obj.YInternal);
        end
        function obj = set.Y(obj,y)
            %set.Y
            obj.YInternal = y;
            obj = obj.updateHt(obj.XInternal, obj.YInternal);
        end
        function obj = set.Theta(obj,theta)
            %set.Theta
            obj.TInternal = theta;
            obj = obj.updateHr(obj.TInternal);
        end

        function x = get.X(obj)
            %get.X
            x = obj.XInternal;
        end
        function y = get.Y(obj)
            %get.Y
            y = obj.YInternal;
        end
        function theta = get.Theta(obj)
            %get.Theta
            theta = obj.TInternal;
        end
    end
    %% Protected Methods
    methods (Access = protected)
        function [q,p1,p2] = supportMapping(geom1,geom2,v)
            %SUPPORTMAPPING Calculates the Minkowski difference between two
            %single vertices that belong to the given convex shapes and
            %returns the coordinates of that point in the configuration
            %space.
            p1 = geom1.supportFunction(v);
            p2 = geom2.supportFunction(-v);
            q = p1-p2;
        end
    end

    methods (Static,Access=protected)
        %TESTSIMPLEX1 Check if the line simplex contains the origin, else
        %find which part of the shape is closest to the origin and set that
        %as the new simplex, setthe new search direction to be from that
        %part of the simplex towards the origin.
        [v, spx, flag] = testSimplex1(W);
        
        %TESTSIMPLEX2 Check if the triangle simplex contains the origin,
        %else find which part of the shape is closest to the origin and set
        %that as the new simplex, setthe new search direction to be from
        %that part of the simplex towards the origin
        [v, spx, flag, W, P, Q] = testSimplex2(W, P, Q, atol);

        function c = cross2d(a,b)
            %CROSS 2D Vector cross product. 
            %   C = cross2d(A,B) returns the norm cross product of the
            %   vectors A anb B. A and B must be 2 element vectors.
            %
            %   For 2D shapes, the position and orientation are represented
            %   in terms of 2 dimensional array. Then, to perform a 2-norm
            %   of [a 0] and [b 0], as in the following:
            %       >> norm(cross([a 0],[b 0]))
            %   Performing the analytical solution of (AxB)xC, we have the
            %   following: 
            %       >> syms a b [3 1] real
            %       >> a(3)=0; b(3)=0;
            %       >> c = norm(cross(a,b),c))
            %       ans
            %           (abs(a1*b2 - a2*b1)^2)^(1/2)
            %
            %   To avoid assemblying array and knowing a3=b3=c3=0, it is
            %   used the analytical solution for better performance.
            %
            %       % #Option1
            %       tic 
            %       for i=1:N   
            %           c = norm(cross([a 0],[b 0]));
            %       end; toc
            %       
            %       % #Option2
            %       tic
            %       for i=1:N
            %           c = abs(a(1)*b(2) - a(2)*b(1));
            %       end; toc              
            %
            %       For N=1e8: #Option1: ~49.94s #Option2: ~.37s

            c = abs(a(1)*b(2) - a(2)*b(1));
        end

        function t = tripleProd(a,b,c)
            %TRIPLEPRODABC 2D Vector cross product of three vectors
            %   T = tripleProdABc(A,B,C) returns the cross product of three
            %   vectors (AxB)xC. 
            %
            %   For 2D shapes, the position and orientation are represented
            %   in terms of 2 dimensional array. Then, to perform a triple
            %   cross product, it is necessary to assembly arrays as in the
            %   following:
            %       >> cross(cross([a 0],[b 0]),[c 0])
            %   Performing the analytical solution of (AxB)xC, we have the
            %   following: 
            %       >> syms a b c [3 1] real
            %       >> t = cross(cross(a,b),c)
            %       ans
            %           - c2*(a1*b2 - a2*b1) - c3*(a1*b3 - a3*b1)
            %             c1*(a1*b2 - a2*b1) - c3*(a2*b3 - a3*b2)
            %             c1*(a1*b3 - a3*b1) + c2*(a2*b3 - a3*b2)
            %
            %   To avoid assemblying array to solve triple cross product,
            %   and knowing a3=b3=c3=0, it is used the analytical solution
            %   for better performance. 
            %
            %       % #Option1
            %       tic 
            %       for i=1:N   
            %           t = cross(cross([a 0],[b 0]),[c 0]);
            %       end; toc
            %       
            %       % #Option2
            %       tic
            %       for i=1:N
            %           t = [-c(2)*(a(1)*b(2) - a(2)*b(1)); ...
            %                c(1)*(a(1)*b(2) - a(2)*b(1))];
            %       end; toc              
            %
            %       For N=1e8: #Option1: ~74.8s #Option2: ~3.9s

            t = [-c(2)*(a(1)*b(2) - a(2)*b(1)); ...
                c(1)*(a(1)*b(2) - a(2)*b(1))];
        end
    end
end