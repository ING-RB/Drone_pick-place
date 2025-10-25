classdef gnssSensor < nav.internal.gnss.GNSSSensorSimulator
%GNSSSENSOR Simulate GNSS position, velocity, and satellites
%   GNSS = GNSSSENSOR returns a System object, GNSS, that computes global 
%   navigation satellite system receiver readings based on local position 
%   and velocity input. The default reference position in geodetic 
%   coordinates is latitude: 0 degrees N, longitude: 0 degrees E, altitude:
%   0 m. 
%
%   GNSS = GNSSSENSOR("ReferenceFrame", RF) returns a GNSSSENSOR System
%   object that computes a global navigation satellite system receiver 
%   reading relative to the reference frame RF. Specify the reference frame
%   as 'NED' (North-East-Down) or 'ENU' (East-North-Up). The default value 
%   is 'NED'. 
% 
%   GNSS = GNSSSENSOR('Name', Value, ...) returns a GNSSSENSOR System 
%   object with each specified property name set to the specified value. 
%   You can specify additional name-value pair arguments in any order as 
%   (Name1,Value1,...,NameN, ValueN). 
%
%   To simulate GNSS receiver readings: 
%   1) Create the GNSSSENSOR object and set its properties. 
%   2) Call the object with arguments, as if it were a function. 
% 
%   [LLA, GNSSVEL, STATUS] = GNSS(POS, VEL) computes GNSS receiver readings
%   from position, POS, and velocity, VEL, inputs.
%    
%   Input arguments: 
% 
%       POS        Position of the GNSS receiver in the local navigation 
%                  coordinate system, specified as a real finite N-by-3  
%                  array in meters. N is the number of samples in the  
%                  current frame. 
% 
%       VEL        Velocity of the GNSS receiver in the local navigation 
%                  coordinate system, specified as a real finite N-by-3  
%                  array in meters per second. N is the number of samples  
%                  in the current frame. 
% 
%   Output arguments:  
% 
%       LLA        Position of the GNSS receiver in the geodetic latitude,
%                  longitude, and altitude coordinate system, returned as a
%                  real finite N-by-3 array. Latitude and longitude are in
%                  degrees with North and East being positive. Altitude is
%                  in meters. N is the number of samples in the current
%                  frame.
% 
%       GNSSVEL    Velocity of the GNSS receiver in the local navigation  
%                  coordinate system, returned as a real finite N-by-3
%                  array in meters per second. N is the number of samples
%                  in the current frame.
% 
%       STATUS    N-by-1 struct array containing additional information  
%                 about the receiver. The struct has the following fields: 
%                     SatelliteAzimuth   - Azimuth of visible satellites 
%                                          (deg) 
%                     SatelliteElevation - Elevation of visible satellites 
%                                          (deg) 
%                     HDOP               - Horizontal dilution of precision
%                     VDOP               - Vertical dilution of precision 
% 
%   Either single or double datatypes are supported for the inputs to  
%   GNSSSENSOR. Outputs have the same datatype as the input. 
% 
%   GNSSSENSOR methods: 
% 
%   step        - Simulate GNSS receiver readings 
%   release     - Allow property value and input characteristics to change,
%                 and release GNSSSENSOR resources
%   clone       - Create GNSSSENSOR object with same property values 
%   isLocked    - Display locked status (logical) 
%   reset       - Reset the states of the GNSSSENSOR 
%
%   GNSSSENSOR properties: 
% 
%   SampleRate            - Sampling rate of receiver (Hz) 
%   InitialTime           - Initial time of receiver clock  
%   ReferenceLocation     - Origin of local navigation reference frame 
%   MaskAngle             - Minimum elevation angle of satellites in view 
%                           (deg) 
%   RangeAccuracy         - Measurement noise in pseudoranges (m)
%   RangeRateAccuracy     - Measurement noise in pseudorange rates (m/s)
%   RandomStream          - Source of random number stream 
%   Seed                  - Initial seed of mt19937ar random number 
%
%   EXAMPLE: Generate GNSS position measurements from stationary input. 
% 
%       Fs = 1; 
%       numSamples = 1000; 
%       t = 0:1/Fs:(numSamples-1)/Fs; 
%       % LLA position for Natick, MA 
%       refLocNatick = [42.2825 -71.343 53.0352]; 
%  
%       gnss = gnssSensor('SampleRate', Fs, ... 
%           'ReferenceLocation', refLocNatick); 
%  
%       pos = zeros(numSamples, 3); 
%       vel = zeros(numSamples, 3); 
%  
%       lla = gnss(pos, vel); 
%
%   See also gpsSensor, imuSensor. 

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen
    
    properties
        %RangeRateAccuracy Measurement noise in pseudorange rates (m/s)
        %   Specify the standard deviation of the noise in the pseudorange
        %   rate measurements as a real scalar in meters per second. This
        %   property is tunable. The default values is 0.02.
        RangeRateAccuracy(1,1) {mustBeNumeric, mustBeReal, ...
            mustBeNonnegative, mustBeFinite} = 0.02;
    end
    
    properties (Constant, Hidden)
        RangeRateAccuracyUnits = 'm/s';
    end
    
    properties (Access = protected)
        % Used to store input for type casting.
        pInputPrototype;
        % Initial receiver position estimate in meters in ECEF coordinate
        % frame.
        pInitPosECEF = [0, 0, 0];
        % Initial receiver velocity estimate in meters per second in ECEF
        % coordinate frame.
        pInitVelECEF = [0, 0, 0];
    end
    
    methods
        function obj = gnssSensor(varargin)
            obj = obj@nav.internal.gnss.GNSSSensorSimulator(varargin{:});
        end
    end
    
    methods (Access = protected)
        groups = getPropertyGroups(obj);
        loadObjectImpl(obj, s, wasLocked);
        resetImpl(obj);
        s = saveObjectImpl(obj);
        setupImpl(obj, pos, vel);
        [lla, gpsVel, status] = stepImpl(obj, pos, vel);
        validateInputsImpl(obj, pos, vel);
    end
end
