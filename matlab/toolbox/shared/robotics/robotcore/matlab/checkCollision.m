function [collisionStatus, separationDist, witnessPts] = checkCollision(geom1, geom2)
%CHECKCOLLISION Report collision status between two convex geometries
%   COLLISIONSTATUS = checkCollision(GEOM1, GEOM2) check if GEOM1 and GEOM2  
%   are in collision at their specified poses, respectively. COLLISIONSTATUS  
%   is set to 1 if collision happens and 0 if no collision is found.
%
%   [COLLISIONSTATUS, SEPDIST, WITNESSPTS] = checkCollision(___) returns  
%   additional information related to the collision check in SEPDIST and  
%   WITNESSPTS. If no collision happens, SEPDIST represents the minimal distance
%   between two geometries and WITNESSPTS represents the witness points 
%   on each geometry (a 3-by-2 matrix, each column is a witness point).
%   The line segment that connects the two witness points realizes the minimal   
%   distance, or the separation distance. When GEOM1 and GEOM2 are in collision,
%   SEPDIST is set to nan, and WITNESSPTS are set to nan(3,2).
%
%   Example:
% 
%      % Create a box primitive 
%      bx = collisionBox(1,2,3);
%
%      % Create a cylinder primitive
%      cy = collisionCylinder(4,2);
%      
%      % Translate the cylinder along x axis
%      T = trvec2tform([2 0 0]);
%      cy.Pose = T;
%
%      % Query collision status
%      [isIntersecting, dist, witnessPoints] = checkCollision(bx, cy);
%
%
%   See also collisionBox, collisionCylinder, collisionSphere,
%   collisionMesh

%   Copyright 2019-2024 The MathWorks, Inc.
%#codegen

narginchk(2,2);

validateattributes(geom1, {'robotics.core.internal.CollisionGeometryBase'}, ...
                            {'scalar', 'nonempty'}, 'checkCollision', 'geom1');
validateattributes(geom2, {'robotics.core.internal.CollisionGeometryBase'}, ...
                            {'scalar', 'nonempty'}, 'checkCollision', 'geom2');
[collisionStatus,separationDist,witnessPts]=robotics.core.internal.checkCollision(geom1,geom2);
end
