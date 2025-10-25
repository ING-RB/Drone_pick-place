function [x,u,v,w,y,dist2] = closestPointOnTetraToOrigin(a,b,c,d)
% closestPointOnTetraToPoint computes the closest point on a tetrahedron
% to origin that is located inside that tetrahedron, the
% barycentric coordinates of that point with respect to the tetrahedron,
% and the minimum distance between that point and the tetrahedron
%
% INPUTS
% a,b,c,d : coordinates of the points of the tetrahedron [3x1]
%
% OUTPUT
% x       : coordinates of the point on the tetrahedron closest to origin [3x1]
% u,v,w,y : scalar barycentric coordinates of x with respect to [a,b,c,d]
% dist2   : scalar squared distance between p and the tetrahedron
%#codegen
 
%   Author: Carlos F. Osorio, Eri Gualter
%   Copyright 2019-2022 The MathWorks, Inc.

% Computing the shortest distance from a point inside a tetrahedron, to
% the tetrahedron itself, is equivalent to computing the smallest of the
% shortest distances between the point and each one of the four triangular
% faces of the tetrahedron

%% Find shortest distance to each face of Tetrahedron
% shortest distance to face abc
[xabc,uabc,vabc,wabc,dabc2] = ...
    controllib.internal.gjk.GJK.closestPointOnTriangleToOrigin(a,b,c);
% shortest distance to face acd
[xacd,uacd,vacd,wacd,dacd2] = ...
    controllib.internal.gjk.GJK.closestPointOnTriangleToOrigin(a,c,d);
% shortest distance to face adb
[xadb,uadb,vadb,wadb,dadb2] = ...
    controllib.internal.gjk.GJK.closestPointOnTriangleToOrigin(a,d,b);
% shortest distance to face bcd
[xbcd,ubcd,vbcd,wbcd,dbcd2] = ...
    controllib.internal.gjk.GJK.closestPointOnTriangleToOrigin(b,c,d);

%% Eliminates problematic distances 
% Exclude barycentric coordinates that doe not satisfy 0<={u,v,w}<=1
infvalue = realmax('like', a);
if any([uabc,vabc,wabc]>=1 | [uabc,vabc,wabc]<=0)
    dabc2 = infvalue;
end
if any([uacd,vacd,wacd]>=1 | [uacd,vacd,wacd]<=0)
    dacd2 = infvalue;
end
if any([uadb,vadb,wadb]>=1 | [uadb,vadb,wadb]<=0)
    dadb2 = infvalue;
end
if any([ubcd,vbcd,wbcd]>=1 | [ubcd,vbcd,wbcd]<=0)
    dbcd2 = infvalue;
end

%% find the smallest of the shortest distances
[dist2,i] = min([dabc2,dacd2,dadb2,dbcd2]);

switch i
    case 1
        % face abc is closest
        x = xabc;
        u = uabc;
        v = vabc;
        w = wabc;
        y = 0*infvalue;
    case 2
        % face acd is closest
        x = xacd;
        u = uacd;
        v = 0*infvalue;
        w = vacd;
        y = wacd;
    case 3
        % face adb is closest
        x = xadb;
        u = uadb;
        v = wadb;
        w = 0*infvalue;
        y = vadb;
    otherwise
        % face bcd is closest
        x = xbcd;
        u = 0*infvalue;
        v = ubcd;
        w = vbcd;
        y = wbcd;  
end

end