function [v, spx, flag, W, P, Q] = testSimplex2(W, P, Q, atol)
%TESTSIMPLEX2 Find which region of the triangle-simplex contains the
%origin, then returns new search direction V, identifier simplex variable
%SPX, and updated simplex information W, P and Q. 
%
% [W, P, Q, v, spx] = testSimplex2(W, P, Q)
%
% Input
%   P, Q: Specified as a 2-by-3 matrix of XY coordinate points of the
%         shapes, where P:=[p1 p2 p3] and Q:=[q1 q2 q3]
%   W   : Specified as a 2-by-3 matrix of coordinate points of Simplex on
%         the Configuration Space, where W:=P-Q.
% Output
%   v   : New search direction vector, specified as a 2-by-1 array.
%   spx : Identifier simplex variable, specified as a scalar.
%   P, Q: Specified as a 2-by-3 matrix of updated XY coordinate points of
%         the shapes
%   W   : Specified as a 2-by-3 matrix of coordinate points of Simplex on
%         the Configuration Space.
%  flag : Returns -1 if the set of simplex vertices is collinear, 1 if
%         origin lies inside the simplex, otherwise returns 0.

%   Author: Eri Gualter
%   Copyright 2022 The MathWorks, Inc.

%#codegen
ONEINT  = int32(1);
ZEROINT = int32(0);

% The triangle simplex is formed by the first two coordinate points of W,
% whose columns are coordinate points [a], [b] and [c]. Then, we need to
% conduct a recursive search to find which region (Voronoi diagram regions:
% abc above, abc below, ab,ac,bc,a,b,c) of the triangle contains the origin

% A PRIORI knowledge to reduce the search: we can exclude the region
% outside [b,c] because the new point [a] was found in a direction
% perpendicular to [b,c] in the direction of the origin we can exclude the
% regions outside point [b] and point [c] because the origin is somewhere
% in between those two points
ab = W(:,2*ONEINT) - W(:,ONEINT);
ac = W(:,3*ONEINT) - W(:,ONEINT);
ao =               - W(:,ONEINT);

% Initiliaze identifier simplex variable as a line
%   1: Point
%   2: Line
%   3: Triangle
spx = 2*ONEINT;

% Initialize collision status flag
flag = ZEROINT;

v = zeros(2,1,'like',W);

%% Edge-case validation
% Search direction v can not be determined if points [a], [b] and [c] from
% 2-simplex are collinear points 

% Computes 'cross' product as: a(1)*b(2) - a(2)*b(1)
abc = controllib.internal.gjk.Base2d.cross2d(ab,ac);

if abs(abc)<=2*atol
    % Points [a], [b] and [c] are collinear points. Update simplex such as
    % the line-simplex is formed by the extremes coordinate points.
    nab = norm(ab);
    nac = norm(ac);
    nbc = norm(W(:,3*ONEINT) - W(:,2*ONEINT));

    if (nac > nab && nac > nbc)        
        % Update point [b]<-[c]
        W(:,[ONEINT 2*ONEINT]) = W(:,[1*ONEINT 3*ONEINT]);
        P(:,[ONEINT 2*ONEINT]) = P(:,[1*ONEINT 3*ONEINT]);
        Q(:,[ONEINT 2*ONEINT]) = Q(:,[1*ONEINT 3*ONEINT]);

    elseif (nbc > nab && nbc > nac)        
        % Update point [a]<-[b], [b]<-[c]
        W(:,[ONEINT 2*ONEINT]) = W(:,[2*ONEINT 3*ONEINT]);
        P(:,[ONEINT 2*ONEINT]) = P(:,[2*ONEINT 3*ONEINT]);
        Q(:,[ONEINT 2*ONEINT]) = Q(:,[2*ONEINT 3*ONEINT]);
    end

    %tripleProd solves cross(cross(ac,ao),ac) for 2D shapes
    % v = controllib.internal.gjk.Base2d.tripleProd(ac,ao,ac);
    flag = -ONEINT;
    return
end

%% Test which region (Voronoi diagram regions)
if dot(ao,ab) < 0 && dot(ao,ac) < ZEROINT
    % the origin will be somewhere in the region outside point [a] reset
    % the simplex to [a] and set the new search direction as the vector
    % from [a] to the origin
    % Then simplex is reduced to a 'point': spx=1.
    v = ao;
    spx = ONEINT;
else
    if dot(controllib.internal.gjk.Base2d.tripleProd(ab,ac,ac),ao) > 0
        if dot(ac,ao)>ZEROINT
            % the origin is somewhere in the region outside [a,c] so the
            % new simplex is [a,c] and the new search direction is
            % perpendicular to [a,c] in the general direction of the origin
            % Then simplex turns to a 'line': spx=2.
        
            % Update point [b]<-[c]
            W(:,2*ONEINT) = W(:,3*ONEINT);
            P(:,2*ONEINT) = P(:,3*ONEINT);
            Q(:,2*ONEINT) = Q(:,3*ONEINT);

            %v = cross(cross(ac,ao),ac);
            v = controllib.internal.gjk.Base2d.tripleProd(ac,ao,ac);
        else
            % the origin is somewhere in the region outside [a,b] so the
            % new simplex is [a,b] and the new search direction is
            % perpendicular to [a,b] in the general direction of the origin
            % Then simplex turns to a 'line': spx=2.

            %v = cross(cross(ab,ao),ab);
            v = controllib.internal.gjk.Base2d.tripleProd(ab,ao,ab);
        end
    elseif dot(controllib.internal.gjk.Base2d.tripleProd(ab,-ac,ab),ao) > ZEROINT
        % the origin is somewhere in the region outside [a,b] so the new
        % simplex is [a,b] and the new search direction is perpendicular to
        % [a,b] in the general direction of the origin
        % Then simplex turns to a 'line': spx=2.

        v = controllib.internal.gjk.Base2d.tripleProd(ab,ao,ab);
    else
        % the origin is somewhere in the region inside the triangle [a,b,c].
        % Shapes are colliding since they are on 2D Plane. If there are
        % located in 3D space, new tests should be performed. 
        flag = ONEINT;
    end
end

