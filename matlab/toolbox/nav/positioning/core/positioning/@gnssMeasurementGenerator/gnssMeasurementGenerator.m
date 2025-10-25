classdef gnssMeasurementGenerator < nav.internal.gnss.GNSSSensorSimulator ...
        & matlabshared.scenario.SensorSimulation.SensorBase
%GNSSMEASUREMENTGENERATOR Simulate GNSS measurements with scenarios
%   GNSS = GNSSMEASUREMENTGENERATOR returns a System object, GNSS, that
%   computes raw global navigation satellite system receiver measurements.
%   The default reference position in geodetic coordinates is latitude: 0
%   degrees North, longitude: 0 degrees East, altitude: 0 m.
% 
%   GNSS = GNSSMEASUREMENTGENERATOR(Name=Value,...) returns a
%   GNSSMEASUREMENTGENERATOR System object with each specified property
%   name set to the specified value. You can set additional properties
%   using one or more name-value pair arguments.
%
%   To simulate GNSS receiver measurements: 
%   1) Create the GNSSMEASUREMENTGENERATOR object and set its properties. 
%   2) Call the object with arguments, as if it were a function. 
% 
%   [PR, SATPOS, STATUS] = GNSS() computes GNSS receiver measurements.
% 
%   Output arguments:  
% 
%       PR        Pseudorange measurements of the GNSS receiver, returned
%                 as an S-element vector in meters. S is the number of
%                 satellites.
% 
%       SATPOS    Satellite positions in the Earth-centered Earth-fixed
%                 coordinate system, returned as an S-by-3 array in meters.
%                 S is the number of satellites.
% 
%       STATUS    Struct containing additional information about the 
%                 measurements. The struct has the following fields: 
%                     LOS - Logical S-element array that indicates
%                           line-of-sight. S is the number of satellites.
% 
%   GNSSMEASUREMENTGENERATOR methods: 
% 
%   step        - Simulate GNSS receiver measurements 
%   release     - Allow property value and input characteristics to change,
%                 and release GNSSMEASUREMENTGENERATOR resources
%   clone       - Create GNSSMEASUREMENTGENERATOR object with same property
%                 values 
%   isLocked    - Display locked status (logical) 
%   reset       - Reset the states of the GNSSMEASUREMENTGENERATOR 
%
%   GNSSMEASUREMENTGENERATOR properties: 
% 
%   SampleRate            - Sampling rate of receiver (Hz) 
%   InitialTime           - Initial time of receiver clock  
%   ReferenceLocation     - Origin of local navigation reference frame 
%   MaskAngle             - Minimum elevation angle of satellites in view 
%                           (deg) 
%   RangeAccuracy         - Measurement noise in pseudoranges (m)
%   RandomStream          - Source of random number stream 
%   Seed                  - Initial seed of mt19937ar random number 
%
%   EXAMPLE: Generate GNSS measurements from a driving scenario. 
% 
%       Fs = 1;
%       % LLA position for Natick, MA 
%       refLocNatick = [42.2825 -71.343 53.0352]; 
% 
%       % Create driving scenario.
%       scene = drivingScenario(GeoReference=refLocNatick);
%       % Add car to scenario.
%       car = vehicle(scene);
% 
%       % Create GNSS measurement generator.
%       gnss = gnssMeasurementGenerator(SampleRate=Fs,...
%           ReferenceLocation=refLocNatick);
% 
%       % Mount the sensor on the car.
%       mountingPosition = [0 0 1.5];
%       addSensors(scene,{gnss},car.ActorID,mountingPosition);
% 
%       % Initialize and advance the scenario.
%       advance(scene);
% 
%       % Get raw GNSS measurements.
%       [pr,satPos,status] = gnss();
%
%   See also gnssSensor, gpsSensor, imuSensor. 

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen
    
    properties (Access = protected)
        % Used to store input for type casting.
        pInputPrototype;
    end

    properties (Access = private)
        SatelliteActorID
        SatellitePosition
        SatelliteParameters;

        SatellitePaths;

        pHostID;
    end

    properties (Access = private, Constant)
        SatelliteSize = 0.1; % m
    end

    methods
        function obj = gnssMeasurementGenerator(varargin)
            obj@nav.internal.gnss.GNSSSensorSimulator(varargin{:});
            obj@matlabshared.scenario.SensorSimulation.SensorBase();
        end
    end
    
    methods (Access = protected)
        groups = getPropertyGroups(obj);
        loadObjectImpl(obj, s, wasLocked);
        resetImpl(obj);
        s = saveObjectImpl(obj);
        setupImpl(obj);
        [p, satPos, status] = stepImpl(obj);
    end

    methods (Hidden)
        sensorConfig = config(obj, hostID, mountingPosition, varargin);
        sensorActorProfiles = customSensorSimInit(obj, varargin);
        newPoses = customSensorSimUpdate(obj, varargin);
    end
end
