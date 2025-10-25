classdef GJK 
    %GJK Base class for <a href="matlab:help controllib.internal.gjk.Base2d">Base2d</a> and <a href="matlab:help controllib.internal.gjk.Base3d">Base3d</a> classes. 
    %
    %   GJK properties (dependent):
    %       is2D       	- Return TRUE if is a 2D shape, and FALSE if it is a 3D shape. 
    %
    %   GJK Protected Methods (static):
	%		solveDistance					- determine the square distance to the origin
	%		closestPointOnEdgeToPoint		- return barycentric coordinates of a simplex-1
	%		closestPointOnTriangleToPoint	- return barycentric coordinates of a simplex-2
	%		closestPointOnTetraToPoint		- return barycentric coordinates of a simplex-3
	%		isSimplexMember					- return true if elements of array w are in W.
	%		minNorm							- returns the norm of the difference between an array and a point.
	%		maxPtNorm						- returns the maximum norm of array.
	%
    %   GJK Abstract Methods:
	%		checkCollision					- Report collision status between two convex geometries.
    %
    %#codegen

    % Author: Eri Gualter
    % Copyright 2022 The MathWorks, Inc.

    %% Hideen Property
    properties (Hidden)
        % is2D placeholder
        Is2D

        %DataType
        DataType
    end

    %% Abstract Method
    methods (Abstract=true,Static)
        [collisionStatus,sepdist,witnesspts,info] = checkCollision(obj,geom1, geom2);
    end

    %% Protected methods
    methods (Static,Access=protected)

        %solveDistance is a protected method in super and is
        % defined in a separated M file 
		%SOLVEDISTANCE determine the square distance to the 
		% origin and return the witness point.
        [witnesspts, dist2] = solveDistance(w,p,q,spx,witnesspts);

        %closestPointOnEdgeToPoint is a protected method in super and is
        % defined in a separated M file. 
        %   closestPointOnEdgeToPoint returns the coordinates of the point
        %   'x' on the edge segment closest to origin, barycentric
        %   coordinates, u and y, of x with respect to [a,b], and squared
        %   distance between p and the edge
        [x,u,v,dist2] = closestPointOnEdgeToOrigin(a,b,p);

        %closestPointOnTriangleToPoint is a protected method in super and is
        % defined in a separated M file. 
        %   closestPointOnTriangleToPoint returns the closest point X on a
        % triangle to the origin that projects onto the face of that triangle,
        % the barycentric coordinates, 'u', 'v', and 'w', of point 'x' with
        % respect to the triangle, and the minimum squared distance 'dist2'
        % between that point and the triangle.
        [x,u,v,w,dist2] = closestPointOnTriangleToOrigin(a,b,c,p);

        %closestPointOnTetraToPoint is a protected method in super and is
        % defined in a separated M file. 
        %   closestPointOnTetraToPoint returns the closest point 'x' on a
        %   tetrahedron to the origin that is located inside that
        %   tetrahedron, the barycentric coordinates, 'u', 'v', 'w', and
        %   'y', of point 'x' with respect to the tetrahedron, and the
        %   minimum squared distance DIST2 between that point and the
        %   tetrahedron
        [x,u,v,w,y,dist2] = closestPointOnTetraToOrigin(a,b,c,d,p);

        function out = isSimplexMember(w,W,spx,tol)
            %isSimplexMember is a protected method wich returns true if
            % the elements of 'w' are in W(:,1:spx). 
            % INPUTS
            %   w    For 2-D and 3-D, w is 2-by-1 and 3-by-1, respectively.
            %   W,   For 2-D and 3-D, w is 2-by-3 and 3-by-4, respectively.
            %   spx, Identifier simplex variable, specified as a scalar.
            % OUTPUT
            %   out  Bollean value equivalent to the following for infinite
            %        precision >> ~ismember(w',W(:,1:spx)','rows')
            out = false;
            for i = int32(1):spx
                e = w-W(:,i);
                if dot(e,e) <= tol
                    out = true;
                    return;
                end
            end
        end

        function out = maxPtNorm(W,spx,dataType)
            %maxPtNorm is a protected method, which returns the maximum
            %norm of Q12(:,1:spx) array.
            % INPUT
            %   W,   For 2-D and 3-D, w is 2-by-3 and 3-by-4, respectively.
            %   spx, Identifier simplex variable, specified as a scalar.
            % OUTPUT
            %   out  Scalar value equivalent to >>min(vecnorm(w-W(:,1:spx))
            % 
            % maxPtNorm is only defined to mitigate DynamicMemoryAllocation
            % issues due to the index "1:spx"
            out = realmin(dataType);
            for i = int32(1):spx
                n = norm(W(:,i));
                if n >= out
                    out = n;
                end
            end
        end
    end
end

% note: minNorm is not being used on GJK for now. Then, to comply with code
% coverage standards, the following is being commented out for now.
%
% function out = minNorm(w,W,spx,dataType)
%     %minNorm is a protected method, which returns the minimum norm
%     %of the difference between a point w and a set of points W.
%     % INPUTS
%     %   w    For 2-D and 3-D, w is 2-by-1 and 3-by-1, respectively.
%     %   W,   For 2-D and 3-D, w is 2-by-3 and 3-by-4, respectively.
%     %   spx, Identifier simplex variable, specified as a scalar.
%     % OUTPUT
%     %   out  Scalar value equivalent to >>min(vecnorm(w-W(:,1:spx))
%     % 
%     % minNorm is only defined to mitigate DynamicMemoryAllocation
%     % issues due to the index "1:spx"
%     out = realmax(dataType);
%     for i = int32(1):spx
%         n = norm(w-W(:,i));
%         if n <= out
%             out = n;
%         end
%     end
% end
