classdef Iaudiorecorder < matlab.mixin.SetGet
    % audiovideo.internal.Iaudiorecorder Abstract base class for
    % audiorecorder. This class contains methods, properties and helpers
    % that are shared between the audiorecorderDesktop and
    % audiorecorderOnline

    %   Copyright 2022 The MathWorks, Inc.

    % --------------------------------------------------------------------
    % General properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='protected')
        SampleRate       = 8000;  % Sampling Frequency in Hz
        BitsPerSample    = 8;     % Number of Bits per audio Sample
        NumChannels      = 1;     % Number of audio channels recording
    end

    properties(Abstract, GetAccess='public', SetAccess='private')
        DeviceID                  % Identifier for audio device in use.
    end

    properties(Abstract, GetAccess='public', SetAccess='private', Dependent)
        CurrentSample           % Current sample that the audio input device is recording
        TotalSamples            % Total length of the audio data in samples.
    end

    properties(GetAccess='public', SetAccess='private', Dependent)
        Running                 % Status of the audio recorder: 'on' or 'off'.
    end

    % --------------------------------------------------------------------
    % Callback Properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='public')
        StartFcn                % Handle to a user-specified callback function that is executed once when playback stops.
        StopFcn                 % Handle to a user-specified callback function that is executed once when playback stops.
        TimerFcn                % Handle to a user-specified callback function that is executed repeatedly (at TimerPeriod intervals) during playback.
        TimerPeriod= 0.05       % Time, in seconds, between TimerFcn callbacks.
        Tag = '';               % User-specified object label string.
        UserData                % Some user defined data.
    end

    properties(GetAccess='public', SetAccess='private', Transient)
        Type = 'audiorecorder'  % For Backward compatibility
    end

    % --------------------------------------------------------------------
    % Persistent internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='protected', SetAccess='protected')
        AudioData               % Audio data recorded.
    end

    properties(GetAccess='protected', SetAccess='protected', Dependent)
        AudioDataType           % Type of the audio signal specified in Matlab type. e.g. 'double', 'single' 'int16', 'int8' etc.
    end


    % --------------------------------------------------------------------
    % Non persistent, internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='protected', SetAccess='protected', Transient)
        Timer                   % Timer object created by the user
        TimerListener           % listen to the Timers ExecuteFcn event
        SamplesToRead           % Number of samples to read during record
        StopCalled    = true;   % Has stopped been called
        IsInitialized = false;  % Has the object been correctly initialized
    end

    % --------------------------------------------------------------------
    % Constants
    % --------------------------------------------------------------------
    properties(GetAccess='protected', Constant)
        MinimumSampleRate  = 80;
        MaximumSampleRate  = 1e6;
        MinimumTimerPeriod = .001;
        MaximumNumChannels = 2
        DesiredLatency     = 0.025;            % The Desired Latency (in seconds) we want the audio device to run at.
        MaxSamplesToRead   = intmax('uint64'); % The maximum number of samples that can be read in a given recording session
        DefaultDeviceID    = -1;
    end


    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Access='public')
        function obj = Iaudiorecorder(varargin)
        end

        function delete(obj)
            cleanUp(obj);
        end
    end


    %----------------------------------------------------------------------
    % Iaudiorecorder Functions
    %----------------------------------------------------------------------
    methods(Abstract, Access='public')
        getaudiodata(obj)
        isrecording(obj)
        pause(obj)
        record(obj)
        recordblocking(obj)
        resume(obj)
        stop(obj);
    end

    methods(Abstract, Access='protected')
        cleanUp(obj)
    end

    methods(Abstract, Static, Hidden)
        loadobj(B)
    end


    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods
        function set.BitsPerSample(obj, value)
            if value ~= 8 && value ~= 16 && value ~= 24
                error(message('MATLAB:audiovideo:audiorecorder:bitsupport'));
            end

            obj.BitsPerSample = value;
        end

        function set.SampleRate(obj, value)
            if value <= obj.MinimumSampleRate || value > obj.MaximumSampleRate
                error(message('MATLAB:audiovideo:audiorecorder:invalidSampleRate', obj.MinimumSampleRate, obj.MaximumSampleRate));
            end

            if ~(isscalar(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audiorecorder:NonscalarSampleRate'));
            end

            obj.SampleRate = value;
        end

        function set.NumChannels(obj, value)
            if ~isscalar(value) || ~(value > 0 && value <= obj.MaximumNumChannels)
                error(message('MATLAB:audiovideo:audiorecorder:numchannelsupport'));
            end

            obj.NumChannels = value;
        end


        function value = get.AudioDataType(obj)
            switch obj.BitsPerSample
                case 8
                    value = 'uint8';
                case 16
                    value = 'int16';
                case 24
                    value = 'double';
                otherwise
                    error(message('MATLAB:audiovideo:audiorecorder:bitsupport'));
            end
        end

        function value = get.Running(obj)
            if obj.isrecording()
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
                error(message('MATLAB:audiovideo:audiorecorder:invalidtimerperiod'));
            end

            obj.TimerPeriod = value;
            obj.Timer.Period = value; %#ok<MCSUP>
        end

        function set.Tag(obj, value)
            if ~(ischar(value) || (isstring(value) && isscalar(value)))
                error(message('MATLAB:audiovideo:audiorecorder:TagMustBeString'));
            end
            obj.Tag = value;
        end

    end
    %----------------------------------------------------------------------
    % Function Callbacks/Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private')
        function executeTimerCallback(obj, ~, ~)
            internal.Callback.execute(obj.TimerFcn, obj);
        end

    end


    %----------------------------------------------------------------------
    % Timer related functionality
    %----------------------------------------------------------------------
    methods(Access='protected')
        function initializeTimer(obj)
            obj.Timer = internal.IntervalTimer(obj.TimerPeriod);

            obj.TimerListener = event.listener(obj.Timer, 'Executing', ...
                @obj.executeTimerCallback);
        end

        function uninitializeTimer(obj)
            if(isempty(obj.Timer) || ~isvalid(obj.Timer))
                return;
            end

            delete(obj.TimerListener);
        end

        function startTimer(obj)
            if isempty(obj.TimerFcn)
                return;
            end

            start(obj.Timer);
        end

        function stopTimer(obj)
            if isempty(obj.TimerFcn)
                return;
            end

            stop(obj.Timer);
        end
    end

    %----------------------------------------------------------------------
    % Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private', Static)
        function validateFcn(fcn)
            if ~internal.Callback.validate(fcn)
                error(message('MATLAB:audiovideo:audiorecorder:invalidfunctionhandle'));
            end
        end

    end

    methods(Access='public')
        function settableProps = getSettableProperties(obj)
            % Returns a list of publicly settable properties.
            % TODO: Reduce to fields(set(obj)) when g449420 is done.
            settableProps = {};
            props = fieldnames(obj);
            for ii=1:length(props)
                p = findprop(obj, props{ii});
                if strcmpi(p.SetAccess,'public')
                    settableProps{end+1} = props{ii}; %#ok<AGROW>
                end
            end
        end

    end

    %----------------------------------------------------------------------
    % Iaudiorecorder Functions
    %----------------------------------------------------------------------
    methods(Access='public')
        function c = horzcat(varargin)
            %HORZCAT Horizontal concatenation of Iaudiorecorder objects.

            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audiorecorder:noconcatenation'));
            end
        end

        function c = vertcat(varargin)
            %VERTCAT Vertical concatenation of Iaudiorecorder objects.

            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audiorecorder:noconcatenation'));
            end
        end


        function ap = getplayer(obj)
            %GETPLAYER Gets associated audioplayer object.
            %
            %    GETPLAYER(OBJ) returns the audioplayer object associated with
            %    this Iaudiorecorder object.
            %
            %    See also AUDIORECORDER, AUDIOPLAYER.

            ap = audioplayer(obj);
        end


        function player = play(obj, varargin)
            %PLAY Plays recorded audio samples in Iaudiorecorder object.
            %
            %    P = PLAY(OBJ) plays the recorded audio samples at the beginning and
            %    returns an audioplayer object.
            %
            %    P = PLAY(OBJ, START) plays the audio samples from the START sample and
            %    returns an audioplayer object.
            %
            %    P = PLAY(OBJ, [START STOP]) plays the audio samples from the START
            %    sample until the STOP sample and returns an audioplayer object.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET, AUDIORECORDER/RECORD.

            narginchk(1,2);

            player = obj.getplayer();
            play(player, varargin{:})
        end

    end
end
