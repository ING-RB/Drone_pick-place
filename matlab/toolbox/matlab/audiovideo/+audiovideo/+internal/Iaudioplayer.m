classdef Iaudioplayer < matlab.mixin.SetGet 
    % audiovideo.internal.Iaudioplayer Abstract base class for audioplayer.
    % This class contains methods, properties and helpers that are shared
    % between the audioplayerDesktop and audioplayerOnline
    
    %   Copyright 2020-2022 The MathWorks, Inc.
        
    % --------------------------------------------------------------------
    % General properties
    % --------------------------------------------------------------------
    properties(Abstract, GetAccess='public', SetAccess='public')
        SampleRate              % Sampling frequency in Hz.
    end
    
    properties(Abstract, GetAccess='public', SetAccess='private')
        DeviceID                % ID of the Device to be used for playback
    end
    
    properties(GetAccess='public', SetAccess='protected')
        BitsPerSample           % Number of bits per audio Sample                
        NumChannels             % Number of channels of the device
    end
    
    % --------------------------------------------------------------------
    % Playback properties
    % --------------------------------------------------------------------
    properties(Abstract, GetAccess='public', SetAccess='protected', Dependent)
        CurrentSample           % Current sample number being played
    end
    
    properties(GetAccess='public', SetAccess='protected', Dependent)
        TotalSamples            % Total number of samples being played
        Running                 % Is the player in running state
    end
    
    % --------------------------------------------------------------------
    % Callback Properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='public')
        StartFcn                % Handle to a user-specified callback function executed once when playback starts.
        StopFcn                 % Handle to a user-specified callback function executed once when playback stops.
        TimerFcn                % Handle to a user-specified callback function executed repeatedly (at TimerPeriod intervals) during playback.
        TimerPeriod = 0.05      % Time, in seconds, between TimerFcn callbacks.
        Tag = ''                % User-specified object label string.
        UserData                % Some user defined data.
    end
    
    
    % --------------------------------------------------------------------
    % Non persistent, internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='protected', SetAccess='protected', Transient)
        Timer                   % Timer object created by the user
        TimerListener           % listener for Timer's ExecuteFcn event
    end
    
   
    % --------------------------------------------------------------------
    % Constants
    % --------------------------------------------------------------------
    properties(Constant, GetAccess='protected')
        MinimumTimerPeriod = .001
        MaximumNumChannels = 2
        DefaultDeviceID    = -1
    end
    
    properties(GetAccess='public', SetAccess='private', Transient)
        Type = 'audioplayer'    % For backward compatibility
    end    
    
    % --------------------------------------------------------------------
    % Persistent internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='protected', SetAccess='protected')
        AudioDataType           % Type of the audio signal specified in Matlab type. e.g. 'double', 'single' 'int16', 'int8' etc.
        AudioData               % Audio data to playback.
    end    
    
    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Access='public')        
        function obj = Iaudioplayer(varargin)      
        end      
    end

   
    methods(Access='public', Hidden)
        function clearAudioData(obj)
            if obj.isplaying
                return; % disallowed during playback
            end
            
            % Remove all audio data
            obj.AudioData = [1 1];
        end
    end
    
    
    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods
        function set.BitsPerSample(obj, value)
            % Check for valid BitsPerSample
            if ~isscalar(value)
                error(message('MATLAB:audiovideo:audioplayer:nonscalarBitsPerSample'));
            end
        
            if value ~= 8 && value ~= 16 && value ~= 24
                error(message('MATLAB:audiovideo:audioplayer:bitsupport'));
            end
            
            obj.BitsPerSample = value;
        end
        
        function set.NumChannels(obj, value)
            if ~(value > 0 && value <= obj.MaximumNumChannels)
                error(message('MATLAB:audiovideo:audioplayer:invalidnumberofchannels'));
            end
            obj.NumChannels = value;
        end
               
        function set.AudioData(obj, value)
            if ~isnumeric(value)
                error(message('MATLAB:audiovideo:audioplayer:invalidsignal'));
            end
            
            if isempty(value)
                error(message('MATLAB:audiovideo:audioplayer:nonemptysignal'));
            end
            
            % transpose row vectors
            [rows, cols] = size(value);
            if cols > rows
                value = value';
            end
            
            % convert int8 to uint8 to preserve 
            % backward compatibility.
            if(isa(value, 'int8'))
                obj.AudioData = uint8(int32(value) + 128);
            else
                obj.AudioData = value;
            end
        end
                
        function value = get.TotalSamples(obj)
            value = size(obj.AudioData, 1);
        end
        
        function value = get.Running(obj)
            if obj.isplaying()
                value = 'on';
            else
                value = 'off';
            end
        end
                
        function set.StartFcn(obj, value)
            obj.validateFcn(value);
            obj.StartFcn = value;
        end
        
        function set.StopFcn(obj, value)
            obj.validateFcn(value);
            obj.StopFcn = value;
        end
        
        function set.TimerFcn(obj, value)
            obj.validateFcn(value);
            obj.TimerFcn = value;
        end
        
        function set.TimerPeriod(obj, value)
            validateattributes(value, {'numeric'}, {'positive', 'scalar'});
            if(value < obj.MinimumTimerPeriod)
                error(message('MATLAB:audiovideo:audioplayer:invalidtimerperiod'));
            end
            
            obj.TimerPeriod = value;
            
            if isTimerValid(obj)
                obj.Timer.Period = value;  %#ok<MCSUP>
            end
        end
        
        function set.Tag(obj, value)
            if ~(ischar(value) || (isstring(value) && isscalar(value)))
                error(message('MATLAB:audiovideo:audioplayer:TagMustBeString'));
            end
            obj.Tag = value;
        end
        
        
    end
    
    %----------------------------------------------------------------------
    % Function Callbacks/Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private')
        
        function executeTimerCallback(obj)  
            internal.Callback.execute(obj.TimerFcn, obj);
        end
        
    end
    
    %----------------------------------------------------------------------
    % Timer related functionalities
    %----------------------------------------------------------------------
    methods(Access='protected')
        function initializeTimer(obj)
            if isempty(obj.TimerFcn)
                % Initialize the timer only if there only if there is a valid
                % TimerFcn.
                return;
            end
            
            obj.Timer = internal.IntervalTimer(obj.TimerPeriod);
            obj.TimerListener = event.listener(obj.Timer, 'Executing', ...
                @(~,~)(obj.executeTimerCallback));
        end
        
        function uninitializeTimer(obj)
            if ~isTimerValid(obj)
                return;
            end
            delete(obj.TimerListener);
            obj.TimerListener = [];
        end
        
        function startTimer(obj)
            if ~isTimerValid(obj)
                return;
            end
            
            start(obj.Timer);
        end
        
        function stopTimer(obj)
            if ~isTimerValid(obj)
                return;
            end
            
            stop(obj.Timer);
        end
   
        function valid = isTimerValid(obj)
            valid = ~isempty(obj.Timer) && isvalid(obj.Timer);
        end
    end
    
    %----------------------------------------------------------------------
    % Helper Functions
    %----------------------------------------------------------------------
    methods(Access='protected', Static)

        function checkNumericArgument(varargin)
            sz = size(varargin, 2);
            for i = 1:sz
                if(~isnumeric(varargin{i}))
                    error(message('MATLAB:audiovideo:audioplayer:numericinputs'));
                end
            end
        end
        
        function bits = getBitsPerSampleForThisSignal(thesignal)
            switch class(thesignal)
                case {'double', 'single', 'int16'}
                    bits = 16;
                case {'int8', 'uint8'}
                    bits = 8;
                otherwise
                    error(message('MATLAB:audiovideo:audioplayer:unsupportedtype'));
            end
        end
        
        function validateFcn(fcn)
            if ~internal.Callback.validate(fcn)
                error(message('MATLAB:audiovideo:audioplayer:invalidfunctionhandle'));    
            end
        end
        
    end

    
    %----------------------------------------------------------------------
    % Iaudioplayer Functions
    %----------------------------------------------------------------------
    methods(Abstract, Access='public')  
        isplaying(obj)
        pause(obj)
        play(obj)
        playblocking(obj)
        resume(obj)
        stop(obj);
    end
    
    methods(Abstract, Access='protected')
        cleanUp(obj)
    end
    
    methods(Abstract, Static, Hidden)  
        loadobj(B)  
    end

    
    methods(Access='public')    
    
        function c = horzcat(varargin)
            %HORZCAT Horizontal concatenation of audioplayer objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audioplayer:noconcatenation'));
            end
        end
        
        function c = vertcat(varargin)
            %VERTCAT Vertical concatenation of audioplayer objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audioplayer:noconcatenation'));
            end
        end    
        
        function delete(obj)
            cleanUp(obj);
        end
    end
end
