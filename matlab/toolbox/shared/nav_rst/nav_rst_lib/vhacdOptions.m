classdef vhacdOptions < matlab.mixin.CustomDisplay
%

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)
        Type
    end

    properties (Dependent)
        VoxelResolution

        MaxNumConvexHulls

        MaxNumVerticesPerHull

        FillMode

        SourceMesh
    end

    properties (Dependent, Access=?robotics.core.internal.InternalAccess)
        %MaxLength Maximum length of any vectors of user-defined parameters
        MaxLength
    end

    properties (SetAccess=private, GetAccess=?robotics.core.internal.InternalAccess)
        %OptionsStruct Struct for use with the internal API
        OptionsStructInternal

        %UseVisualSource Logical indicating whether to use visual or collision mesh source
        UseVisualSource

        %MaxLengthInternal Record of max length
        MaxLengthInternal = 1
    end

    properties (Constant, Access=private)
        %MESHTYPESTRING String used to indication vhacdOptions for an individual mesh
        MESHTYPESTRING = "IndividualMesh"

        %RBTTYPESTRING String used to indication vhacdOptions for a Rigid Body Tree object
        RBTTYPESTRING = "RigidBodyTree"
        %DEFAULTRBTTYPEVOXELRES Default voxel resolution when Type=RigidBodyTree
        %   This lower voxel resolution ensures faster default
        %   decomposition times in importrobot
        DEFAULTRBTTYPEVOXELRES = 2000

        %DEFAULTRBTTYPEMAXNUMHULLS Default number of hulls when Type=RigidBodyTree
        %   This lower maximum number of hulls ensures that collision
        %   checking performance impact is limited when all the rigid
        %   bodies of a robot are decomposed during import
        DEFAULTRBTTYPEMAXNUMHULLS = 8

        %DEFAULTRBTTYPEMAXNUMVERTS Default number of vertices per hull when Type=RigidBodyTree
        %   This lower maximum number of vertices per convex hull ensures
        %   that collision checking performance impact is limited when all
        %   the rigid bodies of a robot are decomposed during import
        DEFAULTRBTTYPEMAXNUMVERTS = 16

        %FLOODFILLSTRING String to indicate fill type: flood fill
        FLOODFILLSTRING = "FLOOD_FILL"

        %SURFACEFILLSTRING String to indicate fill type: surface only fill
        SURFACEFILLSTRING = "SURFACE_ONLY"

        %RAYCASTFILLSTRING String to indicate fill type: raycast fill
        RAYCASTFILLSTRING = "RAYCAST_FILL"
    end

    methods
        function obj = vhacdOptions(type, varargin)

            narginchk(0,9);

            % Read the type and initialize default values
            if nargin < 1
                obj.Type = obj.MESHTYPESTRING;
            else
                obj.Type = validatestring(type, [obj.RBTTYPESTRING obj.MESHTYPESTRING], 'vhacdOptions', 'Type');
            end
            obj = populateDefaultValuesByType(obj);

            % Convert strings to chars case by case
            if nargin > 1
                charInputs = cell(1,nargin-1);
                [charInputs{:}] = convertStringsToChars(varargin{:});
            else
                charInputs = {};
            end

            % Parse inputs
            names = {'VoxelResolution', 'MaxNumConvexHulls', 'MaxNumVerticesPerHull','FillMode', 'SourceMesh'};
            defaults = {obj.VoxelResolution, obj.MaxNumConvexHulls, obj.MaxNumVerticesPerHull, obj.FillMode, "CollisionGeometry"};
            parser = robotics.core.internal.NameValueParser(names, defaults);
            parse(parser, charInputs{:});
            obj.VoxelResolution = parameterValue(parser, names{1});
            obj.MaxNumConvexHulls = parameterValue(parser, names{2});
            obj.MaxNumVerticesPerHull = parameterValue(parser, names{3});
            obj.FillMode = parameterValue(parser, names{4});
            obj.SourceMesh = parameterValue(parser, names{5});
        end

        function obj = set.SourceMesh(obj, srcmesh)
            meshString = validatestring(srcmesh, [robotics.core.internal.VHACDConstants.VISUALGEOMSTRING robotics.core.internal.VHACDConstants.COLLISIONGEOMSTRING], 'vhacdOptions', 'SourceMesh');
            obj.UseVisualSource = strcmp(meshString, robotics.core.internal.VHACDConstants.VISUALGEOMSTRING);
        end

        function srcmesh = get.SourceMesh(obj)
            if obj.UseVisualSource
                srcmesh = robotics.core.internal.VHACDConstants.VISUALGEOMSTRING;
            else
                srcmesh = robotics.core.internal.VHACDConstants.COLLISIONGEOMSTRING;
            end
        end

        function obj = set.VoxelResolution(obj, voxelres)
            validateattributes(voxelres, {'numeric'}, {'vector', 'nonempty', 'nonnan', 'finite', 'integer', 'positive'}, 'vhacdOptions', 'VoxelResolution');
            [obj, voxelresInternal] = obj.validateDimension(voxelres);
            obj.OptionsStructInternal.VoxelResolution = voxelresInternal;
        end

        function voxelres = get.VoxelResolution(obj)
            voxelres = obj.OptionsStructInternal.VoxelResolution;
        end

        function obj = set.MaxNumConvexHulls(obj, numhulls)
            validateattributes(numhulls, {'numeric'}, {'vector', 'nonempty', 'nonnan', 'finite', 'integer', 'positive'}, 'vhacdOptions', 'MaxNumConvexHulls');
            [obj, numhullsInternal] = obj.validateDimension(numhulls);
            obj.OptionsStructInternal.MaxConvHulls = numhullsInternal;
        end

        function numhulls = get.MaxNumConvexHulls(obj)
            numhulls = obj.OptionsStructInternal.MaxConvHulls;
        end

        function obj = set.MaxNumVerticesPerHull(obj, numverts)
            validateattributes(numverts, {'numeric'}, {'vector', 'nonempty', 'nonnan', 'finite', 'integer', 'positive'}, 'vhacdOptions', 'MaxNumVerticesPerHull');
            [obj, numvertsInternal] = obj.validateDimension(numverts);
            obj.OptionsStructInternal.MaxNumVertsPerCH = numvertsInternal;
        end

        function numverts = get.MaxNumVerticesPerHull(obj)
            numverts = obj.OptionsStructInternal.MaxNumVertsPerCH;
        end

        function obj = set.FillMode(obj, fillModeString)
            fillModeString = validatestring(fillModeString, [obj.FLOODFILLSTRING, obj.SURFACEFILLSTRING, obj.RAYCASTFILLSTRING], 'vhacdOptions', 'FillMode');
            switch fillModeString
              case obj.FLOODFILLSTRING
                obj.OptionsStructInternal.FillMode = 0;
              case obj.SURFACEFILLSTRING
                obj.OptionsStructInternal.FillMode = 1;
              case obj.RAYCASTFILLSTRING
                obj.OptionsStructInternal.FillMode = 2;
            end
        end

        function fmString = get.FillMode(obj)
            switch obj.OptionsStructInternal.FillMode
              case 0
                fmString = obj.FLOODFILLSTRING;
              case 1
                fmString = obj.SURFACEFILLSTRING;
              case 2
                fmString = obj.RAYCASTFILLSTRING;
            end
        end

        function obj = set.MaxLength(obj, maxlen)
            obj.MaxLengthInternal = maxlen;
            obj.OptionsStructInternal.VoxelResolution = obj.expandPropValue(obj.OptionsStructInternal.VoxelResolution);
            obj.OptionsStructInternal.ShrinkWrap = obj.expandPropValue(obj.OptionsStructInternal.ShrinkWrap);
            obj.OptionsStructInternal.MaxConvHulls = obj.expandPropValue(obj.OptionsStructInternal.MaxConvHulls);
            obj.OptionsStructInternal.MinErrPercent = obj.expandPropValue(obj.OptionsStructInternal.MinErrPercent);
            obj.OptionsStructInternal.MaxNumVertsPerCH = obj.expandPropValue(obj.OptionsStructInternal.MaxNumVertsPerCH);
            obj.OptionsStructInternal.FillMode = obj.expandPropValue(obj.OptionsStructInternal.FillMode);

        end

        function maxlen = get.MaxLength(obj)
            maxlen = obj.MaxLengthInternal;
        end
    end

    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            if strcmp(obj.Type, obj.RBTTYPESTRING)
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                propList = struct('Type',obj.Type,...
                    'VoxelResolution',obj.VoxelResolution,...
                    'MaxNumConvexHulls',obj.MaxNumConvexHulls,...
                    'MaxNumVerticesPerHull',obj.MaxNumVerticesPerHull,...
                    'FillMode',obj.FillMode);
                propgrp = matlab.mixin.util.PropertyGroup(propList);
            end
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function obj = populateDefaultValuesByType(obj)
        %populateDefaultValuesByType Populate the object with default values for a give type

        % Extract default values from built-in
            obj.OptionsStructInternal = robotics.core.internal.defaultVHACDOpts;

            % Update the defaults if the type is RBT
            if strcmp(obj.Type, obj.RBTTYPESTRING)
                obj.OptionsStructInternal.VoxelResolution = obj.DEFAULTRBTTYPEVOXELRES;
                obj.OptionsStructInternal.MaxConvHulls = obj.DEFAULTRBTTYPEMAXNUMHULLS;
                obj.OptionsStructInternal.MaxNumVertsPerCH = obj.DEFAULTRBTTYPEMAXNUMVERTS;
            end
        end

        function [obj, scaledInput] = validateDimension(obj, input)
        %validateDimension The input must either be a scalar or correspond to the max dimension

            inputLength = numel(input);
            if strcmp(obj.Type, obj.MESHTYPESTRING) && inputLength > 1
                robotics.core.internal.error('vhacd:OptionsIndividualMeshNonScalarPropertyError');
            end

            if inputLength == 1
                scaledInput = repmat(input, [1 obj.MaxLength]);
            elseif inputLength == obj.MaxLength
                scaledInput = input(:)';
            elseif inputLength > 1 && obj.MaxLength == 1
                % First input to exceed 1 sets the max length
                scaledInput = input(:)';
                obj.MaxLength = inputLength;
            else
                robotics.core.internal.error('vhacd:OptionsRBTMeshDimensionsError');
            end
        end

        function newPropValue = expandPropValue(obj, currPropValue)
        %expandPropValue Expand properties to be vector-valued when max length > 1

            if length(currPropValue) == 1
                newPropValue = repmat(currPropValue, [1 obj.MaxLength]);
            end

        end
    end
end
