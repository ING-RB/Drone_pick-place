function [isColliding, details] = checkMapCollision(map,geom,opts)
%checkMapCollision Check for collision between occupancyMap3D and geometry
%
%   Checks for collision between a 3-D occupancy map and a convex collision
%   geometry. The search is typically carried out in two phases, a
%   broad-phase search using simple bounding volumes, followed by a
%   narrow-phase collision check if the simple volumes collide. Simple
%   primitives used here are axially-aligned bounding-boxes (AABB), and the
%   narrow-phase check is between an occupied cell, represented by a
%   collisionBox object, and the input collision geometry object.
%
%   ISCOLLIDING = checkCollision(MAP,GEOMETRY) check if an occupancyMap3D,
%   MAP, and a collision geometry object, GEOMETRY (e.g. collisionMesh) are
%   in collision. ISCOLLIDING is set to 1 if the geometry intersects with
%   any occupied voxel in the map, and 0 if no collision is found.
%
%   [ISCOLLIDING, DETAILS] = checkMapCollision(___, OPTS) accepts OPTS, an
%   occupancyMap3DCollisionOptions object, which modified the behavior of
%   the collision-checking routine. Parameters within OPTS provide control
%   over the search granularity, information returned by the
%   collision-check, and whether to return location/size information of
%   voxels in collision. All additional information is returned in the
%   DETAILS struct, which may contain the following fields:
%
%       DistanceInfo (struct, present when OPTS.ReturnDistance=true)
%           Distance        : scalar double representing minimal distance
%                             between nearest voxel and geometry. Returned
%                             as NaN if collision was found.
%           WitnessPoints   : 3x2 matrix of [X;Y;Z] coordinates, where each
%                             column corresponds to the witness point on
%                             the voxel and collision geometry,
%                             respectively. Returned as nan(3,2) if a
%                             collision was found.
%
%       VoxelInfo (struct, present when OPTS.ReturnVoxels=true)
%           Location       : Nx3 matrix of [X Y Z] coordinates, where each
%                            row represents the center of a colliding voxel
%                            and N is the total number of colliding voxels.
%           Size           : Nx1 matrix of voxel edge-lengths, where the
%                            i'th element defines the size of the voxel
%                            centered at the i'th location.
%
%   Example:
%       % Check for collision between a 3-D map and geometry.
%       map  = occupancyMap3D;
%       setOccupancy(map,[100 50 0],1);
%       geom = collisionSphere(1);
%       isCollidingBroadNarrow = checkMapCollision(map,geom);
%
%       % Only perform a broad-phase check and return distance to nearest
%       % occupied voxel.
%       opts = occupancyMap3DCollisionOptions(CheckNarrowPhase=false,...
%           ReturnDistance=true);
%       [isCollidingNarrow, results] = checkMapCollision(map,geom,opts);
%
%   See also occupancyMap3DCollisionOptions, occupancyMap3D

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    arguments
        map  (1,1) occupancyMap3D
        geom (1,1) {validateGeometry}
        opts (1,1) occupancyMap3DCollisionOptions = occupancyMap3DCollisionOptions
    end

    % Get pointers to map and geometry objects
    collisionHelper = nav.algs.internal.checkMapCollisionBuiltins;
    mapPtr  = collisionHelper.retrieveMapPointer(map);
    [geomPtr, pos, quat] = collisionHelper.retrieveGeometryPointer(geom);

    % Call the internal builtin wrapper
    if nargout == 2
        [isColliding, details] = nav.algs.internal.checkMapCollision(...
            mapPtr, geomPtr, pos, quat, opts);
    else
        isColliding = nav.algs.internal.checkMapCollision(...
            mapPtr, geomPtr, pos, quat, opts);
    end
end

function validateGeometry(geomInput)
%validateGeometry Validator for geometry input
    robotics.internal.validation.validateCollisionGeometry(geomInput,'checkMapCollision','geom');
end
