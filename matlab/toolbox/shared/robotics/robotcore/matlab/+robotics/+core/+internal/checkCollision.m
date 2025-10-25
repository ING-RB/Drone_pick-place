function [collisionStatus,separationDist,witnessPts]=checkCollision(geom1,geom2)
% This function is for internal use only, and maybe removed in the future

%checkCollision Check Collision between two geometries using libccd/GJK

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen
    needMoreInfo = 1;
    if(~coder.target('MATLAB'))
        [collisionStatus, separationDist, witnessPts] =...
        robotics.core.internal.coder.CollisionGeometryBuildable.checkCollision(geom1.GeometryInternal, geom1.Position, geom1.Quaternion,...
                                             geom2.GeometryInternal, geom2.Position, geom2.Quaternion,...
                                             needMoreInfo);
    else 
        [collisionStatus, separationDist, witnessPts] = ...
            robotics.core.internal.intersect(geom1.GeometryInternal, geom1.Position, geom1.Quaternion,...
                                             geom2.GeometryInternal, geom2.Position, geom2.Quaternion,...
                                             needMoreInfo);
    end
    if collisionStatus
        separationDist = nan;
        witnessPts = nan(3,2);
    end
end
