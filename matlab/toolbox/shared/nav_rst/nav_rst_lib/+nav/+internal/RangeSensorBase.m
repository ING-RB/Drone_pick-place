classdef (Hidden) RangeSensorBase < matlab.System ...
        & nav.algs.internal.InternalAccess & matlabshared.autonomous.map.internal.InternalAccess
%RANGESENSORBASE Base class for rangeSensor
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    properties
        % Range Minimum and maximum range
        % Specify the minimum and maximum range as a 2-element array in
        % meters. The default value is [0 20]. This property is tunable.
        Range = [0 20];
    end
    
    properties (Nontunable)
        % HorizontalAngle Minimum and maximum horizontal angle
        % Specify the minimum and maximum horizontal angle as a 2-element
        % array in radians. The default value is [-pi pi].
        HorizontalAngle = [-pi pi];

        % HorizontalAngleResolution Resolution of horizontal angle readings
        % Specify the resolution of the horizontal angle readings as a
        % positive scalar in radians. The default value is 0.0244.
        HorizontalAngleResolution = 2.44e-2;
    end
    
    properties
        % RangeNoise Standard deviation of range noise
        % Specify the standard deviation of the range noise as a scalar
        % in meters. The range noise is modeled as a zero-mean white noise
        % process with RangeNoise standard deviation. The default value is
        % 0. This property is tunable.
        RangeNoise = 0;

        % HorizontalAngleNoise Standard deviation of horizontal angle noise
        % Specify the standard deviation of the horizontal angle noise
        % as a scalar in radians. The horizontal angle noise is modeled as 
        % a zero-mean white noise process with HorizontalAngleNoise 
        % standard deviation. The default value is 0. This property is 
        % tunable.
        HorizontalAngleNoise = 0;
    end
    
    properties (Dependent, SetAccess = private)
        % NumReadings Number of output readings
        % Number of output readings based on HorizontalAngle and
        % HorizontalAngleResolution. The default value is 258. This
        % property is read-only.
        NumReadings;
    end
    
    properties (Access = private)
        % pAngleSweep Used to store noiseless angle readings to prevent
        % re-computation on each call to step.
        pAngleSweep
        
        % Properties for input datatype caching.
        
        pInputPrototype;
        pR;
        pRNoise;
        pHANoise;
    end
    
    methods
        function obj = RangeSensorBase(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    methods (Access = protected)
        function validateInputsImpl(~, robotPose, map)
            validateattributes(robotPose, {'double', 'single'}, ...
                {'ncols', 3, '2d', 'real', 'finite'}, '', 'robotPose');
            
            validateattributes(map, ...
                {'occupancyMap', 'binaryOccupancyMap'}, ...
                {'scalar'}, '', 'map');
        end
        
        function setupImpl(obj, robotPose, ~)
            obj.pInputPrototype = zeros(1, 1, 'like', robotPose);
        end
        
        function resetImpl(obj)
            proto = obj.pInputPrototype;
            setAngleSweep(obj, proto);
            castCachedProperties(obj, proto);
        end
        
        function processTunedPropertiesImpl(obj)
            proto = obj.pInputPrototype;
            if isChangedProperty(obj, 'Range')
                obj.pR = cast(obj.Range, 'like', proto);
            end
            if isChangedProperty(obj, 'RangeNoise')
                obj.pRNoise = cast(obj.RangeNoise, 'like', proto);
            end
            if isChangedProperty(obj, 'HorizontalAngleNoise')
                obj.pHANoise = cast(obj.HorizontalAngleNoise, 'like', ...
                    proto);
            end
        end
        
        function processInputSpecificationChangeImpl(obj, robotPose, ~)
            obj.pInputPrototype = cast(obj.pInputPrototype, 'like', ...
                robotPose);
            castCachedProperties(obj, robotPose);
        end
        
        function castCachedProperties(obj, proto)
            obj.pR = cast(obj.Range, 'like', proto);
            obj.pRNoise = cast(obj.RangeNoise, 'like', proto);
            obj.pHANoise = cast(obj.HorizontalAngleNoise, 'like', proto);
            obj.pAngleSweep = cast(obj.pAngleSweep, 'like', proto);
        end
        
        function [ranges, angles] = stepImpl(obj, robotPose, map)
            
            validateattributes(robotPose, {'double', 'single'}, ...
                {'finite'}, '', 'robotPose');
            
            angles = obj.pAngleSweep;
            numReadings = size(angles, 1);
            numPoses = size(robotPose, 1);
            ranges = NaN(numReadings, numPoses, 'like', robotPose);
            minRange = obj.pR(1);
            maxRange = obj.pR(end);
            rangeNoise = obj.pRNoise;
            
            if isa(map, 'binaryOccupancyMap')
                grid = map.Grid;
            else
                grid = (getValueAllImpl(map) > map.OccupiedThresholdIntLogodds);
            end
            gridSize = map.GridSize;
            resolution = map.Resolution;
            gridLocation = map.GridLocationInWorld;
            rayCastFcn = @(pose) ...
                nav.algs.internal.calculateRanges( ...
                double(pose), double(angles), ...
                double(maxRange), grid, gridSize, resolution, ...
                gridLocation);
            
            validatePoseBounds(robotPose, gridSize, resolution, gridLocation);
            
            zeroVar = zeros(1, 1, 'like', ranges);
            for i = 1:numPoses
                % Calculate measured ranges.
                measRanges = rayCastFcn(robotPose(i,:));
                
                % Remove any measurements less than minimum range.
                measRanges(measRanges < minRange) = NaN;
                
                % Add range noise.
                measRanges = measRanges + randn(numReadings, 1, ...
                    'like', robotPose) .* rangeNoise;
                
                % Saturate negative ranges to zero.
                measRanges((measRanges < zeroVar) & ~isnan(measRanges)) = zeroVar;
                
                ranges(:,i) = measRanges;
            end
            
            % Add horizontal angle noise.
            angles = angles + randn(numReadings, 1, 'like', ...
                robotPose) .* obj.pHANoise;
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);

            % Save private properties. 
            if isLocked(obj)
                s.pAngleSweep = obj.pAngleSweep;
                s.pInputPrototype = obj.pInputPrototype;
                s.pR = obj.pR;
                s.pRNoise = obj.pRNoise;
                s.pHANoise = obj.pHANoise;
            end
        end

        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@matlab.System(obj, s, wasLocked);

            % Load private properties.
            if wasLocked
                obj.pAngleSweep = s.pAngleSweep;
                obj.pInputPrototype = s.pInputPrototype;
                obj.pR = s.pR;
                obj.pRNoise = s.pRNoise;
                obj.pHANoise = s.pHANoise;
            end
        end
    end
    
    methods % Get/Set methods.
        function set.Range(obj, inVal)
            if isscalar(inVal)
                val = [zeros(1, 'like', inVal) inVal];
            else
                val = inVal;
            end
            validateattributes(val, {'double', 'single'}, ...
                {'real', 'finite', 'nonnegative', 'increasing', ...
                'numel', 2}, ...
                '', 'Range');
            obj.Range = val(:).';
        end
        function set.HorizontalAngle(obj, inVal)
            if isscalar(inVal)
                val = [-inVal inVal];
            else
                val = inVal;
            end
            validateattributes(val, {'double','single'}, ...
                {'real', 'finite', 'increasing', 'numel', 2}, ...
                '', 'HorizontalAngle');
            obj.HorizontalAngle = val(:).';
        end
        function set.HorizontalAngleResolution(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'scalar', 'real', 'finite', 'positive'}, ...
                '', 'HorizontalAngleResolution');
            obj.HorizontalAngleResolution = val;
        end
        function set.RangeNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'}, ...
                '', 'RangeNoise');
            obj.RangeNoise = val;
        end
        function set.HorizontalAngleNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'}, ...
                '', 'HorizontalAngleNoise');
            obj.HorizontalAngleNoise = val;
        end
        function val = get.NumReadings(obj)
            horzAngs = obj.HorizontalAngle;
            angleStep = obj.HorizontalAngleResolution;
            val = numel( horzAngs(1):angleStep:horzAngs(2) );
        end
    end
    
    methods (Access = private)
        function setAngleSweep(obj, proto)
            horzAngs = obj.HorizontalAngle;
            angleStep = obj.HorizontalAngleResolution;
            sweep = (horzAngs(1):angleStep:horzAngs(2)).';
            obj.pAngleSweep = cast(sweep, 'like', proto);
        end
    end
end

function validatePoseBounds(pose, gridSize, resolution, gridLocation)
%VALIDATEPOSEBOUNDS Check that input poses are within the map grid.

% Shift and adjust the coordinates using grid location and resolution.
% [x0 y0] is the location of the start point in cell-units, relative to
% the bottom left corner of the grid, gridLocation.
x0 = (pose(:,1) - gridLocation(1,1)).*resolution;
y0 = (pose(:,2) - gridLocation(1,2)).*resolution;

one = ones(1,1,"like", pose);
% Calculate start position
xStart = floor(x0) + one;
yStart = floor(y0) + one;
% The gridSize input is [y,x].
outOfBounds = ~(all(xStart >= one & xStart <= gridSize(2)+one & yStart >= one & yStart <= gridSize(1)+one));
if (outOfBounds)
    error(message("shared_robotics:robotcore:rangeSensor:PoseOutOfBounds","XWorldLimits","YWorldLimits"));
end
end
