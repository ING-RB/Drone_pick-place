classdef gpsSensor < fusion.internal.GPSSensorBase & fusion.internal.UnitDisplayer
    %GPSSENSOR GPS position, velocity, groundspeed, and course measurements
    %   GPS = GPSSENSOR returns a System object, GPS, that computes a global
    %   positioning system receiver reading based on a local position and
    %   velocity input signal. The default reference position in geodetic
    %   coordinates is latitude: 0 degrees N, longitude: 0 degrees E,
    %   altitude: 0 m.
    %
    %   GPS = GPSSENSOR('ReferenceFrame', RF) returns a GPSSENSOR System object
    %   that computes a global positioning system receiver reading relative to
    %   the reference frame RF. Specify the reference frame as 'NED'
    %   (North-East-Down) or 'ENU' (East-North-Up). The default value is 'NED'.
    %
    %   GPS = GPSSENSOR('Name', Value, ...) returns a GPSSENSOR System object
    %   with each specified property name set to the specified value. You can
    %   specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   Step method syntax:
    %
    %   [LLA, VEL, GNDSPD, COURSE] = step(GPS, POS, VEL) computes global
    %   navigation satellite system receiver readings from the position (POS)
    %   and velocity (VEL) inputs.
    %
    %   The inputs to GPSSENSOR are defined as follows:
    %
    %       POS       Position of the GPS receiver in the
    %                 PositionInputFormat coordinate system specified as a
    %                 real finite N-by-3 array in meters. N is the number
    %                 of samples in the current frame.
    %
    %       VEL       Velocity of the GPS receiver in the local navigation
    %                 coordinate system specified as a real finite N-by-3 array
    %                 in meters per second. N is the number of samples in the
    %                 current frame.
    %
    %   The outputs of GPSSENSOR are defined as follows:
    %
    %       LLA       Position of the GPS receiver in the geodetic latitude,
    %                 longitude, and altitude coordinate system returned as a
    %                 real finite N-by-3 array. Latitude and longitude are in
    %                 degrees with north and east being positive. Altitude is
    %                 in meters. N is the number of samples in the current
    %                 frame.
    %
    %       VEL       Velocity of the GPS receiver in the local navigation
    %                 coordinate system returned as a real finite N-by-3 array
    %                 in meters per second. N is the number of samples in the
    %                 current frame.
    %
    %       GNDSPD    Magnitude of the horizontal velocity of the GPS receiver
    %                 in the local navigation coordinate system returned as a
    %                 real finite N-by-1 array in meters per second. N is the
    %                 number of samples in the current frame.
    %
    %       COURSE    Direction of the horizontal velocity of the GPS receiver
    %                 in the local navigation coordinate system returned as a
    %                 real finite N-by-1 array of values between 0 and 360
    %                 degrees. North corresponds to 360 degrees and east
    %                 corresponds to 90 degrees. N is the number of samples in
    %                 the current frame.
    %
    %   Either single or double datatypes are supported for the inputs to
    %   GPSSENSOR. Outputs have the same datatype as the input.
    %
    %   System objects may be called directly like a function instead of using
    %   the step method. For example, y = step(obj, x) and y = obj(x) are
    %   equivalent.
    %
    %   GPSSENSOR methods:
    %
    %   step                          - See above description for use of this
    %                                   method
    %   release                       - Allow property value and input
    %                                   characteristics to change, and release
    %                                   GPSSENSOR resources
    %   clone                         - Create GPSSENSOR object with same
    %                                   property values
    %   isLocked                      - Display locked status (logical)
    %   reset                         - Reset the states of the GPSSENSOR
    %
    %   GPSSENSOR properties:
    %
    %   SampleRate                    - Sampling rate of receiver (Hz)
    %   ReferenceLocation             - Origin of local navigation reference
    %                                   frame
    %   PositionInputFormat           - Position input coordinate format
    %   HorizontalPositionAccuracy    - Horizontal position accuracy
    %   VerticalPositionAccuracy      - Vertical position accuracy
    %   VelocityAccuracy              - Velocity accuracy
    %   DecayFactor                   - Position correlation decay factor
    %   RandomStream                  - Source of random number stream
    %   Seed                          - Initial seed of mt19937ar random number
    %
    %   % EXAMPLE 1: Generate GPS position measurements from stationary input.
    %
    %   Fs = 1;
    %   numSamples = 1000;
    %   t = 0:1/Fs:(numSamples-1)/Fs;
    %   % LLA position for Natick, MA
    %   refLocNatick = [42.2825 -71.343 53.0352];
    %
    %   gps = gpsSensor('SampleRate', Fs, ...
    %       'ReferenceLocation', refLocNatick);
    %
    %   pos = zeros(numSamples, 3);
    %   vel = zeros(numSamples, 3);
    %
    %   llaMeas = gps(pos, vel);
    %
    %   subplot(3, 1, 1)
    %   plot(t, llaMeas(:,1))
    %   title('Latitude')
    %   xlabel('s')
    %   ylabel('degrees')
    %
    %   subplot(3, 1, 2)
    %   plot(t, llaMeas(:,2))
    %   title('Longitude')
    %   xlabel('s')
    %   ylabel('degrees')
    %
    %   subplot(3, 1, 3)
    %   plot(t, llaMeas(:,3))
    %   title('Altitude')
    %   xlabel('s')
    %   ylabel('m')
    %
    %   % EXAMPLE 2: Relationship between Groundspeed and Course Accuracy
    %
    %   % Create a trajectory with constant direction and increasing
    %   % groundspeed. The course measured by the GPS should become more
    %   % accurate as the groundspeed increases.
    %
    %   Fs = 10;
    %   numSamples = 1000;
    %   t = 0:1/Fs:(numSamples-1)/Fs;
    %   % LLA position for Natick, MA
    %   refLocNatick = [42.2825 -71.343 53.0352];
    %
    %   groundspeed = zeros(numSamples,1);
    %   groundspeed((numSamples/2)+1:end) = linspace(0, 1, (numSamples/2)).';
    %   vel = zeros(numSamples,3);
    %   vel(:,2) = groundspeed;
    %   pos = cumsum(vel ./ Fs, 1);
    %
    %   gps = gpsSensor('SampleRate', Fs, ...
    %       'ReferenceLocation', refLocNatick);
    %
    %   gndspdMeas = zeros(numSamples,1);
    %   courseMeas = zeros(numSamples,1);
    %
    %   for i = 1:numSamples
    %       [~, ~, gndspdMeas(i,:), courseMeas(i,:)] = gps(pos(i,:), vel(i,:));
    %   end
    %
    %   subplot(2, 1, 1)
    %   plot(t, gndspdMeas)
    %   title('Groundspeed')
    %   xlabel('s')
    %   ylabel('m/s')
    %
    %   subplot(2, 1, 2)
    %   plot(t, courseMeas)
    %   title('Course')
    %   xlabel('s')
    %   ylabel('degrees')
    
    %   Copyright 2017-2021 The MathWorks, Inc.
    
    %#codegen
    
    properties (Nontunable)
        % SampleRate Sampling rate of receiver (Hz)
        % Specify the sampling rate of the GPS receiver as a positive
        % scalar. The default value is 1.
        SampleRate = 1;
    end
    
    properties (Hidden, Dependent)
        % UpdateRate Update rate (Hz)
        % Specify the update rate of the GPS receiver as a positive scalar.
        % The default value is 1. This is equivalent to the SampleRate
        % property.
        UpdateRate;
    end
    
    properties (Constant, Hidden)
        SampleRateUnits = 'Hz';
        ReferenceLocationUnits = '[deg deg m]';
        HorizontalPositionAccuracyUnits = 'm';
        VerticalPositionAccuracyUnits = 'm';
        VelocityAccuracyUnits = 'm/s';
    end
    
    methods
        function obj = gpsSensor(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    % Get/Set methods
    methods
        function val = get.UpdateRate(obj)
            val = obj.SampleRate;
        end
        function set.UpdateRate(obj, val)
            obj.SampleRate = val;
        end
        function set.SampleRate(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','positive','finite'}, ...
                '', ...
                'SampleRate');
            obj.SampleRate = val;
        end
    end
    
    methods (Access = protected)
        
        
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
        
        function groups = getPropertyGroups(obj)
            list.SampleRate = obj.SampleRate;
            list.PositionInputFormat = obj.PositionInputFormat;
            if ~isInactiveProperty(obj,'ReferenceLocation')
                list.ReferenceLocation = obj.ReferenceLocation;
            end
            list.HorizontalPositionAccuracy = obj.HorizontalPositionAccuracy;
            list.VerticalPositionAccuracy = obj.VerticalPositionAccuracy;
            list.VelocityAccuracy = obj.VelocityAccuracy;
            list.RandomStream = obj.RandomStream;
            if ~isInactiveProperty(obj, 'Seed')
                list.Seed = obj.Seed;
            end
            list.DecayFactor = obj.DecayFactor;
            groups = matlab.mixin.util.PropertyGroup(list);
        end
    end
    
    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
end
