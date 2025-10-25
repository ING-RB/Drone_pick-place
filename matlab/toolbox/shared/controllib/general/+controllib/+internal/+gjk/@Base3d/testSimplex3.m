function [v, spx, flag, W, P, Q] = testSimplex3(W, P, Q, atol)
%TESTSIMPLEX3 Find which region of the tetrahedron-simplex contains the
%origin, then returns new search direction V, identifier simplex variable
%SPX, and updated simplex information W, P and Q. 
%
% [W, P, Q, v, spx] = testSimplex3(W, P, Q)
%
% Input
%   P, Q: Specified as a 3-by-4 matrix of XY coordinate points of the
%         shapes, where P:=[p1 p2 p3 p4] and Q:=[q1 q2 q3 q4]
%   W   : Specified as a 3-by-4 matrix of coordinate points of Simplex on
%         the Configuration Space, where W:=P-Q.
% Output
%   v   : New search direction vector, specified as a 3-by-1 array.
%   spx : Identifier simplex variable, specified as a scalar.
%   P, Q: Specified as a 3-by-4 matrix of updated XY coordinate points of
%         the shapes
%   W   : Specified as a 3-by-4 matrix of coordinate points of Simplex on
%         the Configuration Space.
%  flag : Returns -1 if the set of simplex vertices is collinear, 1 if
%         origin lies inside the simplex, otherwise returns 0.

%   Author: Eri Gualter
%   Copyright 2022 The MathWorks, Inc.

%#codegen
ONEINT  = int32(1);
ZEROINT = int32(0);

% The simplex [a,b,c,d] is currently a tetrahedron (3-simplex). Then, we
% need to conduct a recursive search to find which region of the
% tetrahedron contains the origin

% A PRIORI knowledge to reduce the search: we can exclude the region
% outside [b,c,d] because the new point [a] was found in a direction
% perpendicular to [b,c,d] in the direction of the origin we can exclude
% the regions outside point [b], point [c] and point [d] because the origin
% is somewhere in between those three points
ab = W(:,2*ONEINT) - W(:,ONEINT);
ac = W(:,3*ONEINT) - W(:,ONEINT);
ad = W(:,4*ONEINT) - W(:,ONEINT);
ao =               - W(:,ONEINT);

% Initiliaze identifier simplex variable as a line
%   1: Point
%   2: Line
%   3: Triangle
%   4: Tetrahedron
spx = 4*ONEINT;

% Initialize collision status flag
flag = ZEROINT;

%% Edge-case validation
% The 3-simplex (tetrahedron) might not be a valid tetrahedron if volume is
% zero.
if abs(det(diff(W,[],2))) < atol
    % Edge Case (can not say if there is or not collision)
    flag = -ONEINT;

    % Then simplex is reduced to a 'triangle': spx=3.
    spx = 3*ONEINT;

    % Tetrahedron simplex is not valid. Then, routine is not able to find
    % new search direction
    v = zeros(3,1,'like',W);
    return
end

%% Test which region (Voronoi diagram regions)
if dot(ao,ab) < ZEROINT && dot(ao,ac) < ZEROINT && dot(ao,ad) < ZEROINT
    % the origin will be somewhere in the region outside point [a]
    % reset the simplex to [a] and set the new search direction as the
    % vector from [a] to the origin
    v = ao;

    % simplex is reduced to a 'point': spx=1.
    spx = 1*ONEINT;
else
    % we need to test the three remaining faces [a,b,c], [a,c,d], and
    % [a,d,b] of the tetrahedron

    % define the normal to the plane of the triangle [a,b,c]
    abc = cross(ab,ac);
    % define the normal to the plane of the triangle [a,c,d]
    acd = cross(ac,ad);
    % define the normal to the plane of the triangle [a,d,b]
    adb = cross(ad,ab);

    if dot(abc,ao) > ZEROINT
        % the origin is outside the tetrahedron and somewhere above the
        % [a,b,c] plane
        [v, spx, flag, W, P, Q] = ...
            controllib.internal.gjk.Base3d.testSimplex2(W, P, Q, atol);

    elseif dot(acd,ao) > ZEROINT
        % the origin is outside the tetrahedron and somewhere above the
        % [a,c,d] plane

        W(:,[2*ONEINT 3*ONEINT]) = W(:,[3*ONEINT 4*ONEINT]);
        P(:,[2*ONEINT 3*ONEINT]) = P(:,[3*ONEINT 4*ONEINT]);
        Q(:,[2*ONEINT 3*ONEINT]) = Q(:,[3*ONEINT 4*ONEINT]);
        [v, spx, flag, W, P, Q] = ...
            controllib.internal.gjk.Base3d.testSimplex2(W, P, Q, atol);

    elseif dot(adb,ao) > ZEROINT
        % the origin is outside the tetrahedron and somewhere above the
        % [a,d,b] plane            

        W(:,[2*ONEINT 3*ONEINT]) = W(:,[4*ONEINT 2*ONEINT]);
        P(:,[2*ONEINT 3*ONEINT]) = P(:,[4*ONEINT 2*ONEINT]);
        Q(:,[2*ONEINT 3*ONEINT]) = Q(:,[4*ONEINT 2*ONEINT]);
        [v, spx, flag, W, P, Q] = ...
            controllib.internal.gjk.Base3d.testSimplex2(W, P, Q, atol);
    else
        % the origin is inside the tetrahedron [a,b,c,d] THERE IS AN
        % INTERSECTION BETWEEN THE SHAPES!!! the final simplex will be the
        % tetrahedron [a,b,c,d]

        % 1: collision found
        flag = ONEINT;

        v = zeros(3,1,'like',W);
    end
end