function [iscoll,sdist,wpts]=checkCollision(geom1,geom2)
%checkCollision Check collision between two convex geometries
%   [ISCOLL,SDIST,WPTS]=checkCollision(GEOM1,GEOM2) checks whether two
%   convex collision geometries are in collision. ISCOLL indicates whether
%   the geometries are colliding or not. If they are not colliding SDIST is
%   the separation distance between the two geometries and the WPTS are the
%   witness points or the closest points between the pair of geometries.

%#codegen

%   Copyright 2024 The MathWorks, Inc.

    needMoreInfo = 1;
    if(~coder.target('MATLAB'))
        [iscoll, sdist, wpts] =...
            robotics.core.internal.coder.CollisionGeometryBuildableFunctional.intersect(geom1,...
                                                                                        geom2,...
                                                                                        needMoreInfo);
    else
        [iscoll, sdist, wpts] = ...
            robotics.core.internal.fcn.intersect(geom1,...
                                                 geom2,...
                                                 needMoreInfo);
    end
    if iscoll
        sdist = nan;
        wpts = nan(3,2);
    end
end
