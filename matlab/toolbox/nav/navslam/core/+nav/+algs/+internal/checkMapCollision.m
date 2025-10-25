function [isColliding, details] = checkMapCollision(mapPtr, geomPtr, pos, quat, options)
%This function is for internal use only. It may be removed in the future.

%checkMapCollision Check for collision between occupancyMap3D and collision geometry builtins
%
%   ISCOLLIDING = checkCollision(MAPPTR,GEOMPTR,POS,QUAT,OPTIONS) checks
%   for collision between an MCOS-wrapped OcTree builtin object (MAPPTR)
%   and an MCOS-wrapped CollisionGeometry builtin object (GEOMPTR). By
%   convention, the MAPPTR origin is treated as the world frame, so the
%   1-by-3 position (POS) and 1-by-4 orientation (QUAT) of the geometry
%   should be defined with respect to this frame.
%
%   The last input, OPTIONS, is an occupancyMap3DCollisionOptions object
%   which modified the behavior of the collision-checking routine.
%   Parameters within OPTS provide control over the search granularity,
%   information returned by the collision-check, and whether to return
%   location/size information of voxels in collision. All additional
%   information is returned in the DETAILS struct, which may contain the
%   following fields:
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
%   See also occupancyMap3DCollisionOptions, occupancyMap3D

% Copyright 2022 The MathWorks, Inc.

%#codegen

% Calculate number of outputs from builtin
    nout = coder.const(2 + 2*options.ReturnDistance + 2*options.ReturnVoxels);
    vout = cell(1,nout);

    if coder.target('MATLAB')
        % Call the MCOS builtin
        [vout{1:nout}] = nav.algs.internal.intersect(...
            mapPtr,geomPtr,pos,quat,options.ReturnDistance, ...
            options.Exhaustive,options.CheckNarrowPhase, ...
            options.CheckBroadPhase, options.ReturnVoxels, ...
            options.SearchDepth);
    else
        % Call the deployable C-API
        [vout{1:nout}] = ...
            nav.algs.internal.coder.checkMapCollisionBuildable.intersect( ...
            mapPtr,geomPtr,pos,quat,options.ReturnDistance, ...
            options.Exhaustive,options.CheckNarrowPhase, ...
            options.CheckBroadPhase, options.ReturnVoxels, ...
            options.SearchDepth);
    end

    % Format outputs
    isColliding = double(vout{1});

    if nargout == 2
        details = createDetailsStruct(isColliding, options, vout{:});
    end
end

function details = createDetailsStruct(isColliding, options, varargin)
%createDetailsStruct Populate the details structure
%   Constructs and populates the DETAILS structure, which may contain
%   additional collision-checking results requested in the OPTIONS input.
%
%   See occupancyMap3DCollisionOptions for description of all available options

% Create output structure
    details = struct();

    % Second output contains Distance and Colliding Voxel info
    if options.ReturnDistance
        details.DistanceInfo = struct('Distance',varargin{3},'WitnessPoints',varargin{4});
    end
    if options.ReturnVoxels
        details.VoxelInfo = struct('Location',varargin{end-1},'Size',varargin{end});
    end

    if any(isColliding) && options.ReturnDistance
        details.DistanceInfo.Distance(:)      = nan;
        details.DistanceInfo.WitnessPoints(:) = nan;
    end
end
