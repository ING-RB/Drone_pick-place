classdef Base3d < controllib.internal.gjk.GJK
    %PRIMITIVEBASE3D Base class for 2D geometries
    % 
    % PRIMITIVEBASE3D Public Properties (Dependent):
    %   <a href="matlab:help controllib.internal.gjk.Base3d.Pose">Pose</a>			Pose of shape.
    %
    % PRIMITIVEBASE3D Private Properties:
    %   <a href="matlab:help controllib.internal.gjk.Base3d.PInternal">PInternal</a>   	Stored value of <a href="matlab:help controllib.internal.gjk.Base3d.Pose">Pose.</a>
    %
    % PRIMITIVEBASE3D Public Methods:
    %   <a href="matlab:help controllib.internal.gjk.Base3d.supportMapping">supportMapping</a>	Calculates the Minkowski difference between two convex shapes.
    %
	% PRIMITIVEBASE3D Protected Methods (static)
    %   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex1">testSimplex1</a>	Routine for line simplex
    %   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex2">testSimplex2</a>	Routine for triangle simplex
    %   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex3">testSimplex3</a>	Routine for tetrahedron simplex
	% 
	% PRIMITIVEBASE3D Public Methods (abstract)
	%   <a href="matlab:help controllib.internal.gjk.Base3d.checkCollision">checkCollision</a>	GJK implements the Gilbert-Johnson-Keerthi collision detection algorithm (Main routine)
	%   <a href="matlab:help controllib.internal.gjk.Base3d.generateMesh">generateMesh</a>	Returns the vertex and face values
    %
	% See also <a href="matlab:help controllib.internal.gjk.3d.Box">box</a>, <a href="matlab:help controllib.internal.gjk.3d.Sphere">sphere</a>, <a href="matlab:help controllib.internal.gjk.3d.Cone">cone</a>, <a href="matlab:help controllib.internal.gjk.3d.Cylinder">cylinder</a>, <a href="matlab:help controllib.internal.gjk.3d.Capsule">capsule</a>, <a href="matlab:help controllib.internal.gjk.3d.Mesh">convex mesh</a>.
    %
    %#codegen

    %   Author: Eri Gualter
    %   Copyright 2022 MathWorks, Inc.
    
    %% Dependent Properties
    properties (Dependent)
        % Pose
        %
        %   Default: eye(4)
        Pose
    end
    %% Private Properties
    properties (Access = protected)
        % PInternal
        PInternal
    end
    %% Public Methods
    methods
        function obj = Base3d(pose)
            %PRIMITIVEBASE4D Constructor
            %   Pose of the collision geometry relative to the world frame.
            %   Pose matrix is a 4x4 homogenouts transformation matrix
            %   which contains orientation and position information:
            %
            %       Pose = [R p;    where R is a 3x3 rotation matrix
            %               0 1]    and p is a 3x1 vector that correspond
            %                       to position relative to origin. 
            obj@controllib.internal.gjk.GJK();
            
            % Store Pose
            obj.PInternal = pose;
            obj.DataType = class(pose);
            
            obj.Is2D = false;
            
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
        [V,F] = generateMesh(obj);
    end
    %% Set and Get Methods for Dependent Properties
    methods
        function obj = set.Pose(obj,pose)
            %set.Pose
            obj.PInternal = pose;
        end
        function pose = get.Pose(obj)
            %get.Pose
            pose = obj.PInternal;
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
        %that part of the simplex towards the origin.
        [v, spx, flag, W, P, Q] = testSimplex2(W, P, Q, atol);

        %TESTSIMPLEX3 the simplex is currently a tetrahedron (3-simplex) we
        % need to conduct a recursive search to find which region of the
        % tetrahedron contains the origin.
        [v, spx, flag, W, P, Q] = testSimplex3(W, P, Q, atol);
    end
end