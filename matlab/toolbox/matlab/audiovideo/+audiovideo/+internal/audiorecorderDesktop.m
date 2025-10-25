classdef audiorecorderDesktop <  audiovideo.internal.Iaudiorecorder
    %audiorecorderDesktop Audio recorder object.
    %   audiorecorderDesktop creates an 8000 Hz, 8-bit, 1 channel
    %   audiorecorderDesktop object. A handle to the object is returned.
    %
    %   audiorecorderDesktop(Fs, NBITS, NCHANS) creates an audiorecorderDesktop object with
    %   sample rate Fs in Hertz, number of bits NBITS, and number of channels NCHANS.
    %   Common sample rates are 8000, 11025, 22050, 44100, 48000, and 96000 Hz.
    %   The number of bits must be 8, 16, or 24. The number of channels must
    %   be 1 or 2 (mono or stereo).
    %
    %   audiorecorderDesktop(Fs, NBITS, NCHANS, ID) creates an audiorecorderDesktop object using
    %   audio device identifier ID for input.  If ID equals -1 the default input
    %   device will be used.
    %
    % audiorecorderDesktop Methods:
    %   get            - Query properties of audiorecorderDesktop object.
    %   getaudiodata   - Create an array that stores the recorded signal values.
    %   getplayer      - Create an audioplayer object.
    %   isrecording    - Query whether recording is in progress: returns true or false.
    %   pause          - Pause recording.
    %   play           - Play recorded audio. This method returns an audioplayer object.
    %   record         - Start recording.
    %   recordblocking - Record, and do not return control until recording completes.
    %                    This method requires a second input for the length of the recording in seconds:
    %                    recordblocking(recorder,length)
    %   resume         - Restart recording from paused position.
    %   set            - Set properties of audiorecorderDesktop object.
    %   stop           - Stop recording.
    %
    % audiorecorderDesktop Properties:
    %   BitsPerSample    - Number of bits per sample. (Read-only)
    %   CurrentSample    - Current sample that the audio input device is recording.
    %                      If the device is not recording, CurrentSample is the next
    %                      sample to record with record or resume. (Read-only)
    %   DeviceID         - Identifier for audio device. (Read-only)
    %   NumChannels      - Number of audio channels. (Read-only)
    %   Running          - Status of the audio recorder: 'on' or 'off'. (Read-only)
    %   SampleRate       - Sampling frequency in Hz. (Read-only)
    %   TotalSamples     - Total length of the audio data in samples. (Read-only)
    %   Tag              - character vector or string scalar, that labels the object.
    %   Type             - Name of the class: 'audiorecorder'. (Read-only)
    %   UserData         - Any type of additional data to store with the object.
    %   StartFcn         - Function to execute one time when recording starts.
    %   StopFcn          - Function to execute one time when recording stops.
    %   TimerFcn         - Function to execute repeatedly during recording. To specify
    %                      time intervals for the repetitions, use the TimerPeriod property.
    %   TimerPeriod      - Time in seconds between TimerFcn callbacks.
    %
    % audiorecorderDesktop  Properties (Deprecated):
    %   NOTE: audiorecorderDesktop  ignores any specified values for these properties,
    %         which will be removed in a future release:
    %
    %   BufferLength     - Length of buffer in seconds.
    %   NumberOfBuffers  - Number of buffers
    %
    % Example:
    %     Record your voice on-the-fly.  Use a sample rate of 22050 Hz,
    %     16 bits, and one channel.  Speak into the microphone, then
    %     pause the recording.  Play back what you've recorded so far.
    %     Record some more, then stop the recording. Finally, return
    %     the recorded data to MATLAB as an int16 array.
    %
    %     r = audiorecorderDesktop (22050, 16, 1);
    %     record(r);     % speak into microphone...
    %     pause(r);
    %     p = play(r);   % listen
    %     resume(r);     % speak again
    %     stop(r);
    %     p = play(r);   % listen to complete recording
    %     mySpeech = getaudiodata(r, 'int16'); % get data as int16 array
    %
    % See also AUDIOPLAYER, AUDIODEVINFO, AUDIODEVRESET,
    %          AUDIORECORDER/GET, AUDIORECORDER/SET.

    %    Copyright 2003-2023 The MathWorks, Inc.

    % --------------------------------------------------------------------
    % General properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='private')
        DeviceID                  % Identifier for audio device in use.
    end

    properties(GetAccess='public', SetAccess='private', Dependent)
        CurrentSample           % Current sample that the audio input device is recording
        TotalSamples            % Total length of the audio data in samples.
    end


    % --------------------------------------------------------------------
    % Persistent internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private')
        HostApiID               % API ID for a particular driver model
    end


    % --------------------------------------------------------------------
    % Non persistent, internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private', Transient)
        Channel                 % Source for the audiorecorderDesktop
        ChannelListener         % Listener for Channel events
    end

    % --------------------------------------------------------------------
    % Non persistent, internal, dependent
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private', Dependent)
        Options                 % Options Structure to pass to obj.Channel
    end


    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Access='public')
        function obj = audiorecorderDesktop(sampleRate,numBits,numChannels,deviceID)
            narginchk(0,4);

            obj.DeviceID = obj.DefaultDeviceID;

            if nargin == 1 || nargin == 2
                error(message('MATLAB:audiovideo:audiorecorder:incorrectnumberinputs'));
            end

            if nargin >= 3
                obj.SampleRate = sampleRate;
                obj.BitsPerSample = numBits;
                obj.NumChannels = numChannels;
            end

            if nargin == 4
                obj.DeviceID = deviceID;
            end

            obj.initialize();

            % No audio data recorded yet
            obj.AudioData = [];
        end
    end

    methods(Access='protected')

        function cleanUp(obj)
            if ~obj.IsInitialized
                % obj may be partially initialized
                % during loadobj or if an error occurs
                % in the audiorecorderDesktop  constructor
                return;
            end

            stop(obj);

            obj.uninitialize();
        end

    end

    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence. Forward Declaration.
        %------------------------------------------------------------------
        function obj = loadobj(B)
            %LOADOBJ Load function for audiorecorderDesktop objects.
            %
            %    OBJ = LOADOBJ(B) is called by LOAD when an audiorecorderDesktop  object is
            %    loaded from a .MAT file. The return value, OBJ, is subsequently
            %    used by LOAD to populate the workspace.
            %
            %    LOADOBJ will be separately invoked for each object in the .MAT file.
            %
            %    See also AUDIORECORDER/SAVEOBJ.

            B.initialize();
            obj = B;
        end
    end

    methods(Access='private')
        function initialize(obj)
            % Initialize other un-documented properties.
            obj.SamplesToRead = obj.MaxSamplesToRead;

            % Grab the default device.
            obj.HostApiID = multimedia.internal.audio.device.HostApi.Default;

            % Grab the directory where Converter plugin and device plugin
            % is present. toolboxdir() prefixes correctly if deployed.
            pluginDir = toolboxdir(fullfile('shared','multimedia','bin',...
                computer('arch')));

            % Create Channel object and give it
            try
                obj.Channel = matlabshared.asyncio.internal.Channel( ...
                    fullfile(pluginDir, 'audiodeviceplugin'),...
                    fullfile(pluginDir, 'audiomlconverter'),...
                    Options = obj.Options, ...
                    StreamLimits = [Inf, 0]);
            catch exception
                throw(obj.createDeviceException(exception));
            end


            obj.ChannelListener = event.listener(obj.Channel,'Custom', ...
                @(src,event)(obj.onCustomEvent(event)));

            obj.initializeTimer();

            obj.IsInitialized = true;
        end

        function uninitialize(obj)
            obj.uninitializeTimer();

            delete(obj.ChannelListener);
            obj.Channel.close();

            obj.IsInitialized = false;
        end

    end

    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods

        function set.DeviceID(obj, value)
            if ~(isscalar(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audiorecorder:NonscalarDeviceID'));
            end

            % Get the list of input devices
            devices = multimedia.internal.audio.device.DeviceInfo.getDevicesForDefaultHostApi;
            inputs = devices([devices.NumberOfInputs] > 0);

            if (isempty(inputs))
                error(message('MATLAB:audiovideo:audiorecorder:noAudioInputDevice'));
            end

            if ~(value==obj.DefaultDeviceID || ismember(value, [inputs.ID]))
                error(message('MATLAB:audiovideo:audiorecorder:InvalidDeviceID'));
            end

            obj.DeviceID = value;
        end


        function value  = get.CurrentSample(obj)
            if ~obj.isrecording() && obj.StopCalled
                % stop(obj) was called, reset the current sample
                value = 1;
            else
                % pause(obj) was called, set to the next sample
                value = obj.TotalSamples + 1;
            end
        end


        function value = get.TotalSamples(obj)
            if isempty(obj.Channel)
                value = 0;
            else
                % Initial samples are the total acquired so far
                % plus what is in the Channel's input stream
                value = size(obj.AudioData, 1) + obj.Channel.InputStream.DataAvailable;

                % If the user has requested a certain number of samples, return the
                % up to that value (SamplesToRead)
                value = min(value, obj.SamplesToRead);

                value = double(value);
            end
        end


        function value = get.Options(obj)
            import multimedia.internal.audio.device.DeviceInfo;
            import audiovideo.internal.audio.*;
            value.HostApiID = int32(obj.HostApiID);

            if obj.DeviceID == obj.DefaultDeviceID
                value.DeviceID = int32(DeviceInfo.getDefaultInputDeviceID(obj.HostApiID));
            else
                value.DeviceID = int32(obj.DeviceID);
            end

            % InputChannels is a vector of channel indices to record
            value.InputChannels = int32(1:obj.NumChannels);
            value.SampleRate = uint32(obj.SampleRate);
            value.BitsPerSample = uint32(obj.BitsPerSample);
            value.BufferSize = uint32(Converter.secondsToSamples(...
                obj.DesiredLatency, obj.SampleRate));
            value.QueueDuration = uint32(computeQueueDuration(value.BufferSize));
            value.AudioDataType = obj.AudioDataType;
            value.SamplesUntilDone = obj.SamplesToRead - obj.TotalSamples;
        end
    end

    %----------------------------------------------------------------------
    % Function Callbacks/Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private')

        function onCustomEvent(obj, event)
            % Process any custom events from the Channel
            switch event.Type
                case 'StartEvent'
                    obj.startTimer();
                case 'DoneEvent'
                    stop(obj); % stop if we are done
            end
        end

    end

    %----------------------------------------------------------------------
    % Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private', Static)
        function exp = createDeviceException(exception)
            msg = strrep(exception.message, 'PortAudio', 'Device');
            exp = MException('MATLAB:audiovideo:audiorecorder:DeviceError', msg);
        end
    end

    %----------------------------------------------------------------------
    % audiorecorderDesktop  Functions
    %----------------------------------------------------------------------
    methods(Access='public')

        function status = isrecording(obj)
            %ISRECORDING Indicates if recording is in progress.
            %
            %    STATUS = ISRECORDING(OBJ) returns true or false, indicating
            %    whether recording is or is not in progress.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET.

            status = ~isempty(obj.Channel) && obj.Channel.isOpen();
        end

        function stop(obj)
            %STOP Stops recording in progress.
            %
            %    STOP(OBJ) stops the current recording.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET, AUDIORECORDER/RECORD,
            %             AUDIORECORDER/RECORDBLOCKING, AUDIORECORDER/PAUSE,
            %             AUDIORECORDER/RESUME

            obj.StopCalled = true;
            pause(obj);
        end

        function pause(obj)
            %PAUSE Pauses recording in progress.
            %
            %    PAUSE(OBJ) pauses recording.  Use RESUME or RECORD to resume
            %    recording.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET, AUDIORECORDER/RESUME,
            %             AUDIORECORDER/RECORD.


            if ~isrecording(obj)
                return;
            end

            obj.Channel.close();
            obj.stopTimer();

            internal.Callback.execute(obj.StopFcn, obj);
        end

        function resume(obj)
            %RESUME Resumes paused recording.
            %
            %    RESUME(OBJ) continues recording from paused location.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET, AUDIORECORDER/PAUSE.

            if (obj.isrecording())
                return;
            end

            if (obj.StopCalled)
                obj.StopCalled = false;

                % Remove any buffered data from a previous call to record
                obj.AudioData = [];
                obj.Channel.InputStream.flush();
            end

            %Execute StartFcn
            internal.Callback.execute(obj.StartFcn, obj);

            try
                obj.Channel.open(obj.Options);
            catch exception
                throw(obj.createDeviceException(exception));
            end
        end

        function record(obj, numSeconds)
            %RECORD Record from audio device.
            %
            %    RECORD(OBJ) begins recording from the audio input device.
            %
            %    RECORD(OBJ, T) records for length of time, T, in seconds.
            %
            %    Use the RECORDBLOCKING method for synchronous recording.
            %
            %    Example:  Record your voice on-the-fly.  Use a sample rate of 22050 Hz,
            %              16 bits, and one channel.  Speak into the microphone, then
            %              stop the recording.  Play back what you've recorded so far.
            %
            %       r = audiorecorderDesktop(22050, 16, 1);
            %       record(r);     % speak into microphone...
            %       stop(r);
            %       p = play(r);   % listen to complete recording
            %
            %    See also AUDIORECORDER, AUDIORECORDER/PAUSE,
            %             AUDIORECORDER/STOP, AUDIORECORDER/RECORDBLOCKING.
            %             AUDIORECORDER/PLAY, AUDIORECORDER/RESUME.

            if isrecording(obj)
                return;
            end

            narginchk(1,2);

            if nargin == 2
                if isempty(numSeconds) || ~isnumeric(numSeconds) || (numSeconds <= 0) || isnan(numSeconds)
                    error(message('MATLAB:audiovideo:audiorecorder:recordTimeInvalid'));
                end
                obj.SamplesToRead = uint64(numSeconds * obj.SampleRate);
                if (~obj.StopCalled)
                    obj.SamplesToRead = obj.SamplesToRead + obj.TotalSamples;
                end
            else
                obj.SamplesToRead = obj.MaxSamplesToRead;
            end

            resume(obj);
        end

        function recordblocking(obj, numSeconds)
            %RECORDBLOCKING Synchronous recording from audio device.
            %
            %    RECORDBLOCKING(OBJ, T) records for length of time, T, in seconds;
            %                           does not return until recording is finished.
            %
            %    Use the RECORD method for asynchronous recording.
            %
            %    Example:  Record your voice on-the-fly.  Use a sample rate of 22050 Hz,
            %              16 bits, and one channel.  Speak into the microphone, then
            %              stop the recording.  Play back what you've recorded so far.
            %
            %       r = audiorecorderDesktop(22050, 16, 1);
            %       recordblocking(r, 5);     % speak into microphone...
            %       p = play(r);   % listen to complete recording
            %
            %    See also AUDIORECORDER, AUDIORECORDER/PAUSE,
            %             AUDIORECORDER/STOP, AUDIORECORDER/RECORD.
            %             AUDIORECORDER/PLAY, AUDIORECORDER/RESUME.

            % Error checking.
            if ~isa(obj, 'audiovideo.internal.audiorecorderDesktop')
                error(message('MATLAB:audiovideo:audiorecorder:noAudiorecorderObj'));
            end

            narginchk(2,2);

            % Ignore the command and return if recording is already in progress
            if isrecording(obj)
                return;
            end

            try
                record(obj, numSeconds);
            catch exception
                throwAsCaller(exception);
            end

            pause(numSeconds);

            % Wait until recorder is really stopped
            while obj.isrecording()
                pause(0.01);
            end
        end

        function data = getaudiodata(obj, dataType)
            %GETAUDIODATA Gets recorded audio data in audiorecorderDesktop object.
            %
            %    GETAUDIODATA(OBJ) returns the recorded audio data as a double array
            %
            %    GETAUDIODATA(OBJ, DATATYPE) returns the recorded audio data in
            %    the data type as requested in string DATATYPE.  Valid data types
            %    are 'double', 'single', 'int16', 'uint8', and 'int8'.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/RECORD.

            narginchk(1,2);

            if nargin == 1
                dataType = 'double';
            end

            if isstring(dataType)
                dataType = convertStringsToChars(dataType);
            end

            if ~ischar(dataType)
                error(message('MATLAB:audiovideo:audiorecorder:unsupportedtype'));
            end

            % First, check to see that the datatype requested is supported.
            if ~any(strcmp(dataType, {'double', 'single', 'int16', 'uint8', 'int8'}))
                error(message('MATLAB:audiovideo:audiorecorder:unsupportedtype'));
            end

            % Read all data from the input stream and append it to
            % obj.AudioData
            [newData, countRead, err] = obj.Channel.InputStream.read();
            if ~isempty(err)
                error(message('MATLAB:audiovideo:audiorecorder:ChannelReadError'));
            end

            if (countRead~=0)
                % Append new data to our internal data array
                obj.AudioData = [obj.AudioData; newData];
            end

            if size(obj.AudioData, 1) > obj.SamplesToRead
                % More data has come in than requested
                % Truncate the data to the size requested
                obj.AudioData = obj.AudioData(1:double(obj.SamplesToRead), :);
            end

            if (isempty(obj.AudioData))
                error(message('MATLAB:audiovideo:audiorecorder:recorderempty'));
            end

            % Convert data to requested dataType.
            % Conversion function is the capitalized datatype ('Double','Single',etc)
            % prepended by 'to'.
            % Example: 'double' becomes 'toDouble'
            convertFcn = ['to' upper(dataType(1)) dataType(2:end)];

            data = audiovideo.internal.audio.Converter.(convertFcn)(obj.AudioData);
        end

    end
end
