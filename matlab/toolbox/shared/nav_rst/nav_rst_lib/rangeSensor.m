classdef rangeSensor < nav.internal.RangeSensorBase
%RANGESENSOR Simulate range-bearing sensor readings
%   RBSENSOR = RANGESENSOR returns a System object, RBSENSOR, that computes
%   ranges based on a given sensor pose and an occupancy map. The range
%   readings are based on the obstacles in the map.
%
%   RBSENSOR = RANGESENSOR("Name", Value, ...) returns a RANGESENSOR System
%   object with each specified property name set to the specified value.
%   You can specify additional name-value pair arguments in any order as
%   (Name1,Value1,...,NameN, ValueN).
%
%   To simulate range-bearing sensor readings:
%   1) Create the RANGESENSOR object and set its properties.
%   2) Call the object with arguments, as if it were a function.
%
%   [RANGES, ANGLES] = RBSENSOR(POSE, MAP) computes range and angle 
%   readings from the 2-D pose, POSE, and ground-truth map, MAP. 
%
%   Input Arguments: 
%
%   POSE      Pose of sensor in map, specified as an N-by-3 array, 
%             [x y heading]. [x y] is the global position in the map in
%             meters and heading is measured from the positive x-axis in
%             radians. N is the number of poses to simulate readings from.
%
%   MAP       Ground-truth map, specified as an occupancyMap or 
%             binaryOccupancyMap object. For an occupancyMap object, a cell
%             is considered occupied and returns a range reading if the
%             corresponding probability value is greater than the
%             OccupiedThreshold property.
%
%   Output Arguments: 
%
%   RANGES    Range readings specified as an R-by-N array in meters. R is
%             the number of range readings and N is the number of samples
%             in the current frame.
%
%   ANGLES    Angles corresponding to each range reading specified as an
%             R-by-1 array in radians. R is the number of range readings.
%
%   Either single or double datatypes are supported for the inputs to 
%   RANGESENSOR. Outputs have the same datatype as the input.
%
%   RANGESENSOR methods:
%
%   step     - Simulate range readings
%   clone    - Create RANGESENSOR object with same property values
%
%   RANGESENSOR properties:
%
%   Range                        - Minimum and maximum range
%   HorizontalAngle              - Minimum and maximum horizontal angle
%   HorizontalAngleResolution    - Resolution of horizontal angle readings
%   RangeNoise                   - Noise in range reading (m)
%   HorizontalAngleNoise         - Noise in horizontal angle reading (rad)
%   NumReadings                  - Number of simulated range readings
%
%   % EXAMPLE: Create a lidarScan message.
%
%   % Create the sensor and specify the pose.
%   rangefinder = rangeSensor;
%   truePose = [0 0 pi/4];
%   trueMap = binaryOccupancyMap(eye(10));
%
%   % Generate the scan.
%   [ranges, angles] = rangefinder(truePose, trueMap);
%   scan = lidarScan(ranges, angles);
%
%   % Visualize the scan.
%   figure
%   plot(scan)
%
%   See also IMUSENSOR, GPSSENSOR, ALTIMETERSENSOR.

%   Copyright 2019 The MathWorks, Inc.

%#codegen
    
    methods
        function obj = rangeSensor(varargin)
            obj@nav.internal.RangeSensorBase(varargin{:});
        end
    end
    
    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'nav.internal.coder.rangeSensorCG';
        end
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
end
