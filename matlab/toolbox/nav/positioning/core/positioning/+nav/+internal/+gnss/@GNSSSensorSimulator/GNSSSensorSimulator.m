classdef (Hidden) GNSSSensorSimulator < matlab.System & fusion.internal.UnitDisplayer
%GNSSSENSORSIMULATOR Base class for GNSS sensor simulation
%
%   This class defines and implements common parts of GNSS sensor
%   simulation, such as:
%     - Time conversion to/from UTC and GPS
%     - Random number generation
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %SampleRate Sampling rate of receiver (Hz)
        %   Specify the sampling rate of the GNSS receiver as a positive
        %   scalar. The default value is 1.
        SampleRate(1,1) {mustBeNumeric, mustBePositive, mustBeFinite} = 1;
    end
    
    properties (Nontunable, Dependent)
        %InitialTime Initial time of receiver
        %   Specify the initial time of the GNSS receiver as a scalar
        %   datetime object. If the time zone on the datetime object is not
        %   specified, it is assumed to be UTC. The default value is
        %   datetime("now", "TimeZone", "UTC").
        InitialTime(1,1) datetime;
    end
    
    properties (Nontunable)
        %ReferenceLocation Reference location
        %   Specify the origin of the local coordinate system as a
        %   3-element vector in geodetic coordinates (latitude, longitude,
        %   and altitude). Altitude is the height above the reference
        %   ellipsoid model, WGS84. The reference location is in [degrees
        %   degrees meters]. The default value is [0 0 0].
        ReferenceLocation(1,3) {mustBeNumeric, mustBeReal, ...
            mustBeFinite} = [0, 0, 0];
    end
    
    properties
        %MaskAngle Elevation mask angle (deg)
        %   Specify the mask angle of the GNSS receiver as a scalar between
        %   0 and 90 in degrees. Satellites in view but below the mask
        %   angle are not used in the receiver positioning estimate. This
        %   property is tunable. The default value is 10.
        MaskAngle(1,1) {mustBeNumeric, mustBeReal, ...
            mustBeGreaterThanOrEqual(MaskAngle, 0), ...
            mustBeLessThanOrEqual(MaskAngle, 90)} = 10;
        %RangeAccuracy Measurement noise in pseudoranges (m)
        %   Specify the standard deviation of the noise in the pseudorange
        %   measurements as a real scalar in meters. This property is
        %   tunable. The default values is 1.
        RangeAccuracy(1,1) {mustBeNumeric, mustBeReal, ...
            mustBeNonnegative, mustBeFinite} = 1;
    end
    
    properties (Nontunable)
        %RandomStream Random number source
        %   Specify the source of the random number stream as one of the
        %   following:
        %
        %   'Global stream' - Random numbers are generated using the
        %   current global random number stream.
        %   'mt19937ar with seed' - Random numbers are generated using the
        %   mt19937ar algorithm with the seed specified by the Seed
        %   property.
        %
        %   The default value is 'Global stream'.
        RandomStream (1, :) char {matlab.system.mustBeMember(RandomStream, {'Global stream', 'mt19937ar with seed'})} = 'Global stream';
        %Seed Initial seed
        %   Specify the initial seed of an mt19937ar random number
        %   generator algorithm as a real, nonnegative integer scalar. This
        %   property applies when you set the RandomStream property to
        %   'mt19937ar with seed'. The default value is 67.
        Seed(1,1) uint32 {mustBeReal} = uint32(67);
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Constant, Hidden)
        SampleRateUnits = 'Hz';
        ReferenceLocationUnits = '[deg deg m]';
        MaskAngleUnits = 'deg';
        RangeAccuracyUnits = 'm';
    end
    
    properties (Abstract, Access = protected)
        % Used to store input for type casting.
        pInputPrototype;
    end
    properties (Access = protected)
        % Current simulation time in seconds.
        pCurrTime;
        
        % Used to keep InitialTime display consistent in MATLAB.
        pTimeZone = '';
        pFormat = 'dd-MMM-uuuu HH:mm:ss';
    end
    properties (Access = protected, Nontunable)
        % Date and time value from InitialTime property stored as a GPS
        % week number and a time of week (TOW) in seconds.
        pGPSWeek;
        pTimeOfWeek;
    end
    
    properties (Nontunable, Access = protected)
        % Cached reference frame.
        pRefFrame;
    end
    
    properties (Access = private)
        % Random stream object (used in 'mt19937ar with seed' mode).
        pStream;
        % Random number generator state.
        pStreamState;
    end
    
    methods
        function obj = GNSSSensorSimulator(varargin)
            coder.extrinsic('matlabshared.internal.gnss.GNSSTime.getGNSSTime');
            
            setProperties(obj, nargin, varargin{:});
            
            setInitialTime = true;
            for i = 1:2:numel(varargin)-1
                if strcmp(varargin{i}, 'InitialTime')
                    setInitialTime = false;
                    break;
                end
            end
            if setInitialTime
                if isempty(coder.target)
                    % In MATLAB, set the initial time to the local date and
                    % time.
                    obj.InitialTime = datetime('now', 'TimeZone', 'UTC');
                else
                    % In code generation, if the initial time is not set,
                    % only set the underlying values (GPS week and time of
                    % week) to a constant value.
                    [obj.pGPSWeek, obj.pTimeOfWeek] = coder.const( ...
                        @matlabshared.internal.gnss.GNSSTime.getGNSSTime);
                end
            end
        end
        
        function val = get.InitialTime(obj)
            coder.extrinsic('matlabshared.internal.gnss.GNSSTime.getLocalTime');
            
            if isempty(coder.target)
                % Get datetime object from underlying values.
                val = matlabshared.internal.gnss.GNSSTime.getLocalTime(obj.pGPSWeek, ...
                obj.pTimeOfWeek, obj.pTimeZone);
                val.TimeZone = obj.pTimeZone;
                val.Format = obj.pFormat;
            else
                % Get equivalent numeric datetime without time zone or
                % format.
                val = coder.const(@matlabshared.internal.gnss.GNSSTime.getLocalTime, ...
                    obj.pGPSWeek, obj.pTimeOfWeek);
            end
        end
        function set.InitialTime(obj, val)
            coder.extrinsic('matlabshared.internal.gnss.GNSSTime.getGNSSTime');
            
            if isempty(coder.target)
                if isempty(val.TimeZone)
                    val.TimeZone = 'UTC';
                end
                % Save underlying values of datetime object.
                [obj.pGPSWeek, obj.pTimeOfWeek] ...
                    = matlabshared.internal.gnss.GNSSTime.getGNSSTime(val);
                obj.pTimeZone = val.TimeZone;
                obj.pFormat = val.Format;
                if ~contains(val.Format, ["x", "z"], 'IgnoreCase', true)
                        obj.pFormat = [val.Format, ' z'];
                end
            else
                % Save underlying numeric values of datetime object, while
                % ensuring it can be reduced to a constant value.
                nonConstDateTimeInCG = ~coder.internal.isConst(val);
                coder.internal.errorIf(nonConstDateTimeInCG, ...
                    'Coder:builtins:NonTunablePropertyNotConst', ...
                    'InitialTime');
                [obj.pGPSWeek, obj.pTimeOfWeek] = coder.const( ...
                    @matlabshared.internal.gnss.GNSSTime.getGNSSTime, val);
            end
        end
        
        function set.ReferenceLocation(obj, val)
            obj.ReferenceLocation = val;
            validateattributes(obj.ReferenceLocation(1), {'numeric'}, ...
                {'>=',-90,'<=',90}, ...
                '', ...
                'Latitude');
            validateattributes(obj.ReferenceLocation(2), {'numeric'}, ...
                {'>=',-180,'<=',180}, ...
                '', ...
                'Longitude');
        end
    end
    
    methods (Access = protected)
        displayScalarObject(obj);
        flag = isInactivePropertyImpl(obj, prop);
        loadObjectImpl(obj, s, wasLocked);
        resetImpl(obj);
        s = saveObjectImpl(obj);
        setupImpl(obj);
        noise = stepRandomStream(obj, numSamples, numChans);
    end
    
    methods (Static, Hidden)
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
end
