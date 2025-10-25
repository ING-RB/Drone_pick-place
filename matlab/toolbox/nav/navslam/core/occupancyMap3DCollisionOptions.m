classdef occupancyMap3DCollisionOptions
%occupancyMap3DCollisionOptions Collision check options for occupancyMap3D
%
%   OPTS = OCCUPANCYMAP3DCOLLISIONOPTIONS returns a collision checking
%   options object, OPTS, for the checkMapCollision function, which checks
%   for collision between an occupancyMap3D and collision geometry object.
%
%   OPTS = OCCUPANCYMAP3DCOLLISIONOPTIONS(Name=Value,...) returns a
%   occupancyMap3DCollisionOptions object, OPTS, with each specified
%   property name set to the specified value. You can specify additional
%   name-value pair arguments in any order as
%   (Name1=Value1,...,NameN=ValueN).
%
%   occupancyMap3DCollisionOptions properties:
%       CheckBroadPhase     - Check for collision using AABB
%       CheckNarrowPhase    - Check for collision using geometry
%       Exhaustive          - Whether function exits at first collision
%       ReturnDistance      - Return closest point and distance
%       ReturnVoxels        - Return location and size of colliding voxel
%       SearchDepth         - Max depth used during search
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
%   See Also: checkMapCollision, occupancyMap3D

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    properties
        %CheckBroadPhase Check for collision between AABB and voxels
        %
        %   When TRUE, simplified collision check between voxels and
        %   bounding geometry are performed. If CheckNarrowPhase=TRUE,
        %   broad-phase checks which report collision trigger narrow-phase
        %   checks.
        %
        %   Default: true
        CheckBroadPhase (1,1) double {mustBeNumericOrLogical, mustBeInteger, occupancyMap3DCollisionOptions.validateLogicalRange} = true

        %CheckNarrowPhase Check for collision between underlying geometry
        %
        %   When TRUE, checks for intersection between voxel and the raw
        %   input geometry are performed. If CheckBroadPhase=TRUE, voxels
        %   must first fail the broad-phase check before narrow-phase check
        %   is triggered.
        %
        %   Default: true
        CheckNarrowPhase (1,1) double {mustBeNumericOrLogical, mustBeInteger, occupancyMap3DCollisionOptions.validateLogicalRange} = true

        %Exhaustive Determines whether function exits upon first valid collision
        %
        %   If TRUE, the function will return all voxels that are in
        %   collision. When CheckNarrowPhase=FALSE, voxels are in collision
        %   with the bounding primitive. When CheckNarrowPhase=TRUE, voxels
        %   are in collision with both bounding primitive and geometry.
        %
        %   Default: false
        Exhaustive (1,1) double {mustBeNumericOrLogical, mustBeInteger, occupancyMap3DCollisionOptions.validateLogicalRange} = false

        %ReturnDistance Return closest point and distance between map and geometry
        %
        %   When TRUE, checkMapCollision returns minimum distance between
        %   map and the collision geometry object, and WitnessPoints. If
        %   collision has been found, all values are NaN.
        %
        %   Default: false
        ReturnDistance (1,1) double {mustBeNumericOrLogical, mustBeInteger, occupancyMap3DCollisionOptions.validateLogicalRange} = false

        %ReturnVoxels Return location and size of voxel(s) in collision
        %
        %   Default: false
        ReturnVoxels (1,1) double {mustBeNumericOrLogical, mustBeInteger, occupancyMap3DCollisionOptions.validateLogicalRange} = false

        %SearchDepth Determines max depth used during search
        %
        %   Limits checks to the SearchDepth depth in the tree. The maximum
        %   depth is 16, corresponding to voxels whose edge length is
        %   1/map.Resolution. Each level above the maximum depth doubles
        %   this minimum voxel size.
        %
        %   Default: 16 (finest resolution)
        SearchDepth (1,1) {mustBeNumeric, mustBeInteger, occupancyMap3DCollisionOptions.validateSearchDepthRange} = 16
    end

    methods
        function obj = occupancyMap3DCollisionOptions(varargin)
            coder.internal.prefer_const(varargin);
            nvPairs = obj.parseInputs(varargin{:});

            names = fieldnames(nvPairs);
            for i = 1:numel(names)
                obj.(names{i}) = nvPairs.(names{i});
            end
        end

        function obj = set.CheckBroadPhase(obj, tf)
            coder.internal.errorIf(coder.target("MATLAB") && obj.CheckNarrowPhase == false && tf == false,"nav:navalgs:checkmapcollision:BroadNarrowFalse"); %#ok<MCSUP>
            obj.CheckBroadPhase = tf;
        end

        function obj = set.CheckNarrowPhase(obj, tf)
            coder.internal.errorIf(coder.target("MATLAB") && obj.CheckBroadPhase == false && tf == false,"nav:navalgs:checkmapcollision:BroadNarrowFalse"); %#ok<MCSUP>
            obj.CheckNarrowPhase = tf;
        end
    end
    methods (Static, Hidden)
        function nvPairs = parseInputs(varargin)
        %parseInputs Parse name-value pair inputs
            coder.internal.prefer_const(varargin);
            % Get default values
            defaultValues = coder.internal.constantPreservingStruct(...
                'CheckNarrowPhase', true, ...
                'CheckBroadPhase', true, ...
                'Exhaustive', false, ...
                'SearchDepth', 16, ...
                'ReturnDistance', false, ...
                'ReturnVoxels', false);

            % Parse (validation is handled by Function Argument validators)
            nvPairs = coder.internal.nvparse(defaultValues,varargin{:});
        end
        
        function value = validateLogicalRange(value)
        %validateLogicalRange Ensure numeric inputs are logically-valued
            occupancyMap3DCollisionOptions.validateRange(value,{'numeric','logical'},{'scalar','>=',0,'<=',1});
        end
        function value = validateSearchDepthRange(value)
        %validateSearchDepthRange Ensure SearchDepth is within valid range
            occupancyMap3DCollisionOptions.validateRange(value,{'numeric'},{'scalar','>=',0,'<=',16});
        end
        function validateRange(value,allowedType,range)
            validateattributes(value,allowedType,range,'occupancyMap3DCollisionOptions');
        end
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'ReturnDistance', 'ReturnVoxels'};
        end
    end
end
