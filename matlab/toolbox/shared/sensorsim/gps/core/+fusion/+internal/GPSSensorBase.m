classdef GPSSensorBase < matlab.System
    %This function is for internal use only. It may be removed in the future.
    
    %GPSSensorBase Base class for gpsSensor in MATLAB and Simulink
    
    %   Copyright 2021-2022 The MathWorks, Inc.
    
    %#codegen
    
    properties (Nontunable, Abstract)
        % SampleRate Sampling rate of receiver (Hz)
        % Specify the sampling rate of the GPS receiver as a positive
        % scalar. The default value is 1.
        SampleRate;
    end
    
    properties (Nontunable)
        
        % ReferenceLocation Reference location
        % Specify the origin of the local coordinate system as a 3-element
        % row vector in geodetic coordinates (latitude, longitude, and
        % altitude). Altitude is the height above the reference ellipsoid
        % model, WGS84. The reference location is in
        % [degrees degrees meters]. The default value is [0 0 0].
        ReferenceLocation = [0 0 0];
        
        % PositionInputFormat Position input format
        % Specify the coordinate system format used to describe the
        % position input to the step method as one of the following:
        %
        % 'Local' - Position is  defined with local navigation Cartesian
        % coordinates. The origin of the system is ReferenceLocation.
        % 'Geodetic' - Position is defined with geodetic latitude,
        % longitude, and altitude. ReferenceLocation is not used in
        % this configuration.
        % The default value is 'Local'.
        PositionInputFormat = 'Local';
    end
    
    properties
        % HorizontalPositionAccuracy Horizontal position accuracy (m)
        % Specify the standard deviation of the noise in the horizontal
        % position measurement as a real scalar. This property is tunable.
        % The default value is 1.6.
        HorizontalPositionAccuracy = 1.6;
        
        % VerticalPositionAccuracy Vertical position accuracy (m)
        % Specify the standard deviation of the noise in the vertical
        % position measurement as a real scalar. This property is tunable.
        % The default value is 3.
        VerticalPositionAccuracy = 3;
        
        % VelocityAccuracy Velocity accuracy (m/s)
        % Specify the standard deviation of the noise in the velocity
        % measurement as a real scalar. This property is tunable. The
        % default value is 0.1.
        VelocityAccuracy = 0.1;
        
        % DecayFactor Global position noise decay factor
        % Specify the global position noise decay factor as a real scalar
        % with a value between 0 and 1, inclusive. A decay factor of
        % 0 models the global position noise as a white noise process. A
        % decay factor of 1 models the global position noise as a random
        % walk process. This property is tunable. The default value is
        % 0.999.
        DecayFactor = 0.999;
    end
    
    properties (Nontunable)
        % RandomStream Random number source
        % Specify the source of the random number stream as one of the
        % following:
        %
        % 'Global stream' - Random numbers are generated using the current
        % global random number stream.
        % 'mt19937ar with seed' - Random numbers are generated using the
        % mt19937ar algorithm with the seed specified by the Seed property.
        %
        % The default value is 'Global stream'.
        RandomStream = 'Global stream';
        
        % Seed Initial seed
        % Specify the initial seed of an mt19937ar random number generator
        % algorithm as a real, nonnegative integer scalar. This property
        % applies when you set the RandomStream property to
        % 'mt19937ar with seed'. The default value is 67.
        Seed = uint32(67);
    end
    
    properties (Constant, Hidden)
        RandomStreamSet = matlab.system.StringSet({...
            'Global stream', ...
            'mt19937ar with seed'});
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
        
        PositionInputFormatSet = matlab.system.internal.MessageCatalogSet({...
            'shared_sensorsim_gps:gpsSensor:PositionInputFormatLocal',...
            'shared_sensorsim_gps:gpsSensor:PositionInputFormatGeodetic'});
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Nontunable, Access = private)
        % Cached reference frame.
        pRefFrame;
    end
    
    properties (Access = private)
        % Random stream object (used in 'mt19937ar with seed' mode).
        pStream;
        % Random number generator state.
        pStreamState;
        %Position error filter parameters.
        pPositionErrorFilterNum;
        pPositionErrorFilterDen;
        pPositionErrorFilterStates;
        pSigmaScaled;
    end
    
    properties (Access = private, Constant)
        MAX_COURSE = 360;
    end
    
    methods
        function obj = GPSSensorBase(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    % Get/Set methods
    methods
        function set.ReferenceLocation(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','finite','numel',3}, ...
                '', ...
                'ReferenceLocation');
            validateattributes(val(1), {'double','single'}, ...
                {'>=',-90,'<=',90}, ...
                '', ...
                'Latitude');
            validateattributes(val(2), {'double','single'}, ...
                {'>=',-180,'<=',180}, ...
                '', ...
                'Longitude');
            % Ensure it is a row vector.
            obj.ReferenceLocation = val(:).';
        end
        function set.HorizontalPositionAccuracy(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','nonnegative','finite'}, ...
                '', ...
                'HorizontalPositionAccuracy');
            obj.HorizontalPositionAccuracy = val;
        end
        function set.VerticalPositionAccuracy(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','nonnegative','finite'}, ...
                '', ...
                'VerticalPositionAccuracy');
            obj.VerticalPositionAccuracy = val;
        end
        function set.VelocityAccuracy(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','nonnegative','finite'}, ...
                '', ...
                'VelocityAccuracy');
            obj.VelocityAccuracy = val;
        end
        function set.Seed(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real','scalar','integer','>=',0,'<',2^32}, ...
                '', ...
                'Seed');
            obj.Seed = uint32(val);
        end
        function set.DecayFactor(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','>=',0,'<=',1}, ...
                '', ...
                'DecayFactor');
            obj.DecayFactor = val;
        end
    end
    
    methods (Access = protected)
        function setupRandomStream(obj)
            % Setup Random Stream object if required.
            if strcmp(obj.RandomStream, 'mt19937ar with seed')
                if isempty(coder.target)
                    obj.pStream = RandStream('mt19937ar', 'seed', obj.Seed);
                else
                    obj.pStream = coder.internal.RandStream('mt19937ar', 'seed', obj.Seed);
                end
            end
        end
        
        function setupPositionErrorFilter(obj, dataType)
            obj.pPositionErrorFilterStates = zeros(1, 3, dataType);
        end
        
        function setupImpl(obj, pos, ~)
            setupRandomStream(obj);
            setupPositionErrorFilter(obj, class(pos));
            obj.pRefFrame = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
        end
        
        function noise = stepRandomStream(obj, numSamples, numChans, isGaussianNoise)
            % Noise (random number) generation.
            if strcmp(obj.RandomStream, 'Global stream')
                if isGaussianNoise
                    noise = randn(numSamples, numChans);
                else
                    noise = rand(numSamples, numChans);
                end
            else
                if isGaussianNoise
                    noise = randn(obj.pStream, numSamples, numChans);
                else
                    noise = rand(obj.pStream, numSamples, numChans);
                end
            end
        end
        
        function out = stepPositionErrorFilter(obj, randNums)
            [out, obj.pPositionErrorFilterStates] = ...
                filter(obj.pPositionErrorFilterNum, ...
                obj.pPositionErrorFilterDen, ...
                bsxfun(@times, randNums, obj.pSigmaScaled), ...
                obj.pPositionErrorFilterStates, 1);
        end
        
        function courseErr = stepCourseError(obj, gndSpeed)
            frameSize = size(gndSpeed);
            
            isGaussianNoise = (gndSpeed > 0);
            
            courseSigma = obj.VelocityAccuracy ./ gndSpeed;
            courseSigma(~isGaussianNoise) = obj.MAX_COURSE;
            
            courseErr = zeros(frameSize);
            for i = 1:numel(gndSpeed)
                courseErr(i) = stepRandomStream(obj, 1, 1, isGaussianNoise(i));
            end
            courseErr = courseSigma .* courseErr;
        end
        
        function course = wrapToMaxCourse(obj, course)
            isPositive = (course > 0);
            course = mod(course, obj.MAX_COURSE);
            course((course == 0) & isPositive) = obj.MAX_COURSE;
        end
        
        function num = getNumInputsImpl(~)
            num = 2;
        end
        
        function [llaMeas, velMeas, groundspeedMeas, courseMeas] ...
                = stepImpl(obj, pos, vel)
            numSamples = size(pos, 1);
            refFrame = obj.pRefFrame;
            
            randNums = stepRandomStream(obj, numSamples, 3, true);
            posErr = stepPositionErrorFilter(obj, randNums);
            
            gndSpeed = sqrt(sum(vel(:,1:2).^2, 2));
            randNums = stepRandomStream(obj, numSamples, 3, true);
            velErr = obj.VelocityAccuracy .* randNums;
            gndSpeedErr = sqrt(sum(velErr(:,1:2).^2, 2));
            zVelErr = velErr(:,3);
            course = atan2d(vel(:,refFrame.EastIndex), ...
                vel(:,refFrame.NorthIndex));
            courseErr = stepCourseError(obj, gndSpeed);
            
            if strcmp(obj.PositionInputFormat,'Local')
                localPosMeas = pos + posErr;
                reference = obj.ReferenceLocation;
            else
                localPosMeas = posErr;
                reference = pos;
            end
            
            llaMeas = refFrame.frame2lla(localPosMeas, reference);
            
            groundspeedMeas = gndSpeed + gndSpeedErr;
            courseMeas = course + courseErr;
            courseMeas = wrapToMaxCourse(obj, courseMeas);
            
            velMeasN = groundspeedMeas .* cosd(courseMeas);
            velMeasE = groundspeedMeas .* sind(courseMeas);
            velMeas = NaN(size(vel), 'like', vel);
            velMeas(:,refFrame.NorthIndex) = velMeasN;
            velMeas(:,refFrame.EastIndex) = velMeasE;
            velMeas(:,3) = vel(:,3) + zVelErr;
        end
        
        function validateInputsImpl(~, pos, vel)
            validateattributes(pos, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3});
            validateattributes(vel, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3, 'nrows', size(pos, 1)});
        end
        
        function processTunedPropertiesImpl(obj)
            posPropsChanged = ...
                isChangedProperty(obj, 'HorizontalPositionAccuracy') ...
                || isChangedProperty(obj, 'VerticalPositionAccuracy') ...
                || isChangedProperty(obj, 'DecayFactor');
            if posPropsChanged
                resetPositionErrorFilterNoise(obj);
            end
        end
        
        function resetRandomStream(obj)
            if strcmp(obj.RandomStream, 'mt19937ar with seed')
                obj.pStream.reset;
            end
        end
        
        function resetPositionErrorFilter(obj)
            resetPositionErrorFilterNoise(obj);
            resetPositionErrorFilterStates(obj);
        end
        
        function resetPositionErrorFilterNoise(obj)
            dt = 1 ./ obj.SampleRate;
            decayFactor = obj.DecayFactor;
            
            tau = dt / (1-decayFactor);
            horzSigma = obj.HorizontalPositionAccuracy;
            vertSigma = obj.VerticalPositionAccuracy;
            sigmas = [horzSigma horzSigma vertSigma];
            
            obj.pSigmaScaled = sigmas .* sqrt(2.*dt./tau);
            obj.pPositionErrorFilterNum = 1;
            obj.pPositionErrorFilterDen = [1 -decayFactor];
        end
        
        function resetPositionErrorFilterStates(obj)
            obj.pPositionErrorFilterStates = zeros( ...
                size(obj.pPositionErrorFilterStates), 'like', ...
                obj.pPositionErrorFilterStates);
        end
        
        function resetImpl(obj)
            resetRandomStream(obj);
            resetPositionErrorFilter(obj);
        end
        
        function flag = isInputComplexityMutableImpl(~, ~)
            flag = false;
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);
            
            % Save private properties.
            if isLocked(obj)
                s.pPositionErrorFilterNum    = obj.pPositionErrorFilterNum;
                s.pPositionErrorFilterDen    = obj.pPositionErrorFilterDen;
                s.pPositionErrorFilterStates = obj.pPositionErrorFilterStates;
                s.pSigmaScaled               = obj.pSigmaScaled;
                s.pRefFrame                  = obj.pRefFrame;
                
                if strcmp(obj.RandomStream, 'mt19937ar with seed')
                    if ~isempty(obj.pStream)
                        s.pStreamState = obj.pStream.State;
                    end
                end
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties.
            loadObjectImpl@matlab.System(obj, s, wasLocked);
            
            % Load private properties.
            if wasLocked
                obj.pPositionErrorFilterNum    = s.pPositionErrorFilterNum;
                obj.pPositionErrorFilterDen    = s.pPositionErrorFilterDen;
                obj.pPositionErrorFilterStates = s.pPositionErrorFilterStates;
                obj.pSigmaScaled               = s.pSigmaScaled;
                obj.pRefFrame                  = s.pRefFrame;
                
                if strcmp(s.RandomStream, 'mt19937ar with seed')
                    obj.pStream = RandStream('mt19937ar', ...
                        'seed', obj.Seed);
                    if ~isempty(s.pStreamState)
                        obj.pStream.State = s.pStreamState;
                    end
                end
            end
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            if strcmp(prop, 'Seed')
                if strcmp(obj.RandomStream, 'Global stream')
                    flag = true;
                end
            elseif strcmp(prop, 'ReferenceLocation')
                if strcmp(obj.PositionInputFormat, 'Geodetic')
                    flag = true;
                end
            end
        end
        
    end
end
