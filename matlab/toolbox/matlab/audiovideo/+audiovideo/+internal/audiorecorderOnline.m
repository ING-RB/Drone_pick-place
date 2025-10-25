classdef audiorecorderOnline < audiovideo.internal.Iaudiorecorder
    % AUDIORECORDERONLINE Implements the
    % functionalities in Iaudiorecorder to support recording from audio
    % input devices in MATLAB Online

    % Copyright 2022-2023 The MathWorks, Inc.

    properties(GetAccess='public', SetAccess='private')
        DeviceID        % Identifier for audio device in use.
    end

    properties(GetAccess='public', SetAccess='private', Dependent)
        CurrentSample   % Current sample that the audio input device is recording
        TotalSamples    % Total length of the audio data in samples.
    end

    properties(Hidden)
        RecordReceived  % Flag to track if front-end is ready to record
        PauseReceived   % Flag to track if front-end is ready to pause
        ResumeReceived  % Flag to track if front-end is ready to resume
        StopReceived    % Flag to track if front-end is ready to stop
        ErrorReceived   % Property containing error message from JS code
    end

    properties (Access = private)
        IsRecording = false         % Flag to indicate if recording is in progress
        UseBinaryTransport = true   % Flag to indicate if binary transport is in use
        RecordUsed = false          % Flag to indicate if recording was done atleast once
        RequiredSamplesRecorded = false    % Flag to indicate if required samples for record(obj,length) or recordblocking(obj,duration) is recorded
    end

    properties(Access = private)
        ControlChannel = "/audiorecorder/audioControl"
        StreamingChannel = "audioStreaming"
        BackupStreamingChannel = "/audiorecorder/audioStreaming"
        DebugWebAppPath = 'toolbox/shared/aviswebaudiorecorder/index-debug.html'
        MessageHandler
        Url
        InternalDeviceID
        BinaryChannelHandle
        MsgServiceStreamingSubscriber
        AudioRefreshListener
        SamplesRequiredToStopRecord
    end

    %% Audio recorder public functions
    methods (Access = public)

        function obj = audiorecorderOnline(sampleRate, bitsPerSample, numChannels, deviceID)

            arguments
                sampleRate      (1,1) double {mustBeNonempty, mustBeNonNan, mustBeNumeric, mustBeReal} = 0
                bitsPerSample   (1,1) double {mustBeNonempty, mustBeNonNan, mustBeNumeric, mustBeReal} = 0
                numChannels     (1,1) double {mustBeNonempty, mustBeNonNan, mustBeInteger, mustBeReal} = 0
                deviceID        (1,1) double {mustBeNonempty, mustBeNonNan, mustBeInteger, mustBeReal} = -1
            end

            import audiovideo.internal.AudioDeviceTypeEnums

            % Check if audio input devices are available
            deviceAvailable = hasNoAudioHardware(obj);
            if ~deviceAvailable
                error(message('MATLAB:audiovideo:audiorecorder:noAudioInputDevice'));
            end

            narginchk(0,4);

            % User needs to specify all of sample rate, number
            % of bits, and number of channels as properties
            if nargin == 1 || nargin == 2
                error(message('MATLAB:audiovideo:audiorecorder:incorrectnumberinputs'));
            end
            obj.DeviceID = obj.DefaultDeviceID;

            if nargin >= 3
                obj.SampleRate = sampleRate;
                obj.NumChannels = numChannels;
                obj.BitsPerSample = bitsPerSample;
            end

            if nargin == 4
                % Validate device ID
                ID = audiovideo.internal.audio.utility.getInternalDeviceIDFromID(...
                    AudioDeviceTypeEnums.InputDevice, deviceID);
                if strcmpi(ID, 'invalid')
                    error(message('MATLAB:audiovideo:audiorecorder:InvalidDeviceID'));
                end
                obj.DeviceID = deviceID;
            end

            obj.SamplesToRead = obj.MaxSamplesToRead;

            % Initialize audio data buffer and create
            % connections
            obj.AudioData = [];
            obj.StopCalled = false;
            createConnection(obj);

            % For audiorecorder index page debug, this is done manually
            % after we open the web page
            initializeRecorder(obj);
        end

        function initializeRecorder(obj)
            % Attach the listener to "reconnectWithDevice" event in case of
            % Browser Refresh
            instance = audiovideo.internal.audioplayerrecorderOnlineBrowserRefresh.Instance;
            obj.AudioRefreshListener = event.listener(instance, 'reconnectWithDevice', ...
                @(eventObj, source) onBrowserRefresh(obj));

            import audiovideo.internal.audio.utility
            import audiovideo.internal.AudioDeviceTypeEnums

            obj.InternalDeviceID = utility.getInternalDeviceIDFromID( ...
                AudioDeviceTypeEnums.InputDevice, obj.DeviceID);
            params = struct("sampleRate", obj.SampleRate, "numChannels", obj.NumChannels, "deviceId", obj.InternalDeviceID);
            obj.MessageHandler.publish('initializeRecorder', params);

            % Initialize the timer to execute during record
            obj.initializeTimer();
        end

        function recordingStatus =  isrecording(obj)
            % Get current status of recording

            % Binary channel state can be one of OPEN, IDLE,
            % or CLOSE
            if strcmpi(string(obj.BinaryChannelHandle.state),"CLOSE")
                obj.IsRecording = false;
            end
            recordingStatus = obj.IsRecording;
        end

        function record(obj,varargin)
            % Function to start recording audio

            narginchk(1,2);

            obj.RecordReceived = false;

            % Ignore if recording is already in progress
            if isrecording(obj)
                return;
            end

            if obj.StopCalled
                % Clear any buffered audio data from previous
                % record
                obj.StopCalled = false;
                obj.AudioData = [];
            end

            % Set samples to read to max samples limit for
            % non-blocking record
            if nargin == 2
                % Calculate the final sample count after blocking record
                duration = varargin{1};
                validateattributes(duration,{'numeric'},{'positive','scalar','nonnan'});
                obj.SamplesToRead = duration * obj.SampleRate;
                obj.SamplesRequiredToStopRecord = obj.SamplesToRead;
                obj.RequiredSamplesRecorded = false;
            else
                obj.SamplesToRead = obj.MaxSamplesToRead;
            end

            % Start timer to execute TimerFcn callback and
            % execute StartFcn callback
            startTimer(obj);
            internal.Callback.execute(obj.StartFcn,obj);

            % Send request and wait for ACK from the JS front-end
            obj.MessageHandler.publish('startRecording', {});
            waitfor(obj, "RecordReceived", true);

            % Throw error if operation threw error from JS front-end
            validateCommandExecution(obj);

            obj.RecordUsed = true;
            obj.IsRecording = true;
        end

        function recordblocking(obj,duration)
            % Function to record data blocking the MATLAB
            % command line

            validateattributes(duration,{'numeric'},{'positive','scalar','nonnan','finite'});

            % Ignore if recording is already in progress
            if isrecording(obj)
                return;
            end

            % Start Recording
            record(obj,duration);

            % Wait until the desired number of samples are
            % received
            while(~obj.RequiredSamplesRecorded)
                % Make way for the binary transport callback
                matlab.internal.yield();
            end

            % Stop recording
            stop(obj);

            if length(obj.AudioData) > obj.SamplesToRead
                % More data has come in than requested
                % Truncate the data to the size requested
                obj.AudioData = obj.AudioData(1:double(obj.SamplesToRead), :);
            end
        end

        function pause(obj)
            % Function to pause the recording

            obj.PauseReceived = false;
            % Send request and wait for ACK from the JS front-end
            obj.MessageHandler.publish('pauseRecording', {});
            waitfor(obj, "PauseReceived", true);

            % Throw error if operation threw error from JS front-end
            validateCommandExecution(obj);

            obj.IsRecording = false;
            % Stop timer for TimerFcn callback and execute StopFcn callback
            stopTimer(obj);
            internal.Callback.execute(obj.StopFcn, obj);
        end

        function resume(obj)
            % Function to resume audio recording

            % Ignore if recording is already in progress
            if isrecording(obj)
                return;
            end

            if obj.StopCalled
                % Clear any buffered audio data from previous
                % record
                obj.StopCalled = false;
                obj.AudioData = [];
            end

            % Start recording audio if resume was the first
            % function to be called even before record
            if ~obj.RecordUsed
                record(obj);
                obj.RecordUsed = true;
                return;
            end

            % Start timer for TimerFcn callback and execute
            % StartFcn callback
            startTimer(obj);
            internal.Callback.execute(obj.StartFcn,obj);

            % Send request and wait for ACK from the JS front-end
            obj.ResumeReceived = false;
            obj.MessageHandler.publish('resumeRecording', {});
            waitfor(obj, "ResumeReceived", true);

            % Throw error if operation threw error from JS front-end
            validateCommandExecution(obj);

            obj.IsRecording = true;
        end

        function stop(obj)
            % Function to stop audio recording

            % Check to ensure the message handler is instantiated for the case when recordr construction
            % failed before creating a msg service connection
            if ~isempty(obj.MessageHandler)
                % Send request and wait for ACK from the JS front-end
                obj.StopReceived = false;
                obj.MessageHandler.publish('stopRecording', {});
                waitfor(obj, "StopReceived", true);

                % Throw error if operation threw error from JS front-end
                validateCommandExecution(obj);
            end

            % Set flags
            obj.IsRecording = false;
            obj.RecordUsed = false;
            obj.StopCalled = true;

            % Stop timer for TimerFcn callback and execute
            % StopFcn callback
            stopTimer(obj);
            internal.Callback.execute(obj.StopFcn, obj);
        end

        function audioData = getaudiodata(obj,dataType)
            % Get recorded audio data in the desired format

            arguments
                obj         (1,1) audiovideo.internal.audiorecorderOnline
                dataType    (1,:) char {mustBeMember(dataType,{'double', 'single', 'int16', 'uint8', 'int8'})} = 'double'
            end

            if (isempty(obj.AudioData))
                error(message('MATLAB:audiovideo:audiorecorder:recorderempty'));
            end

            % Convert data to requested dataType.
            % Conversion function is the capitalized datatype ('Double','Single',etc)
            % prepended by 'to'.
            % Example: 'double' becomes 'toDouble'
            audioData = [];
            convertFcn = ['to' upper(dataType(1)) dataType(2:end)];
            audioData = audiovideo.internal.audio.Converter.(convertFcn)(obj.AudioData);
        end

        function loadobj(obj)
            % Re-establish connections and initialize recorder
            obj.IsRecording = false;
            createConnection(obj);
            initializeRecorder(obj);
        end
    end

    %% Getters and setters
    methods

        function value  = get.CurrentSample(obj)
            if ~obj.isrecording()
                value = 1;
            else
                value = obj.TotalSamples + 1;
            end
        end

        function value = get.TotalSamples(obj)

            value = length(obj.AudioData);
            % If the user has requested a certain number of samples, return the
            % up to that value (SamplesToRead)
            value = double(min(value, obj.SamplesToRead));
        end

    end

    %% Hidden functions
    methods(Hidden)

        function url = getUrl(obj)
            if ~isempty(obj.Url)
                url = obj.Url;
                return
            end
            url = connector.getUrl(obj.DebugWebAppPath);
            obj.Url = url;
        end

        function clientError(obj, errorData)
            % Handle errors thrown from the JS layer
            errorData = string(errorData);
            % Get error message key from JS
            errorKey = sprintf("MATLAB:audiovideo:audiorecorder:%s",errorData(1));
            if length(errorData) > 1
                obj.ErrorReceived = message(errorKey,errorData(2));
            else
                obj.ErrorReceived = message(errorKey);
            end
        end

        function clientSwitchToMsgService(obj, ~)
            obj.UseBinaryTransport = false;
        end

        function clientReceivedHandler(obj, msg)
            % msg will be one of "RecordReceived", "PauseReceived",
            % "ResumeReceived" and "StopReceived".
            obj.(msg) = true;
        end
    end

    %% Private internal functions
    methods(Access = private)

        function subscribeToClientActions(obj)
            obj.MessageHandler.subscribe("clientError");
            obj.MessageHandler.subscribe("clientSwitchToMsgService")
            obj.MessageHandler.subscribe("clientReceivedHandler")
        end

        function validateCommandExecution(obj)
            % Function to validate if command execution threw error in JS
            % layer
            if ~isempty(obj.ErrorReceived)
                ex = MException(obj.ErrorReceived);
                obj.ErrorReceived = [];
                throwAsCaller(ex);
            end
        end

        function handleStreamingData(obj, data)
            % Callback function that executes after audio data is
            % received in MATLAB

            if obj.UseBinaryTransport
                % Append data received from the binary stream
                % after typecasting it to single data type
                data = cast(typecast(data,"single"),"double");
            end
            data = cast(data,"double");

            % Reshape data from a vector to a n-by-2 matrix
            if obj.NumChannels == 2
                data = reshape(data, [], 2);
            end
            obj.AudioData = [obj.AudioData; data];

            if ~isempty(obj.SamplesRequiredToStopRecord) && ...
                    obj.TotalSamples >= obj.SamplesRequiredToStopRecord
                obj.RequiredSamplesRecorded = true;
                obj.SamplesRequiredToStopRecord = [];
                stop(obj);
            end
        end

        function deviceAvailable = hasNoAudioHardware(~)
            % hasNoAudioHardware() returns a boolean based on whether any audio
            % input device is found.
            [~, ~, audioInputDeviceID, errorMsg] = audiovideo.internal.audio.utility.enumerateAudioInputDevicesOnBrowser;
            if ~isempty(errorMsg)
                throwAsCaller(MException('MATLAB:audiovideo:audiorecorder:noAudioInputDevice', errorMsg));
            end
            % Return true if device is available
            deviceAvailable = ~isempty(audioInputDeviceID);
        end

        function onBrowserRefresh(obj)
            % Add code to handle browser refresh

            % Set recording states to false and re-initialize recorder
            obj.IsRecording = false;
            obj.RecordUsed = false;
            initializeRecorder(obj);
            % Refresh audio device cache
            audiovideo.internal.audio.utility.resetAudioDevices;
        end

        function createConnection(obj)
            % Create message service channel for sending
            % control commands
            obj.MessageHandler = audiovideo.internal.audio.MessageHandler(obj.ControlChannel);
            obj.MessageHandler.setSubject(obj);
            obj.subscribeToClientActions();
            obj.StreamingChannel = obj.StreamingChannel + "_" + obj.MessageHandler.ClientId;
            obj.BackupStreamingChannel = obj.BackupStreamingChannel + "/" + obj.MessageHandler.ClientId;

            % Create binary transport connection for streaming
            % audio data
            obj.BinaryChannelHandle = connector.internal.binary.BinaryStream(char(obj.StreamingChannel));
            obj.BinaryChannelHandle.receive(@(msg) obj.handleStreamingData(msg));

            % Set up the backup msg service channel for streaming
            % We always set it up at the beginning to save time in case of
            % switching and avoid losing data
            obj.MsgServiceStreamingSubscriber = message.subscribe(obj.BackupStreamingChannel, @(msg) obj.handleStreamingData(msg));
        end
    end

    methods (Access = protected)

        function cleanUp(obj)

            % Stop recording
            stop(obj);

            % Clean up message audio message handler and the
            % binary transport
            if ~isempty(obj.MessageHandler)
                obj.MessageHandler.publish('deleteRecorder', {});
                delete(obj.MessageHandler);
                obj.MessageHandler = [];
            end

            if ~isempty(obj.BinaryChannelHandle)
                delete(obj.BinaryChannelHandle);
                obj.BinaryChannelHandle = [];
            end
            obj.IsRecording = false;
            obj.RecordUsed = false;
        end

    end
    methods (Hidden)
        %  Get the status of binary transport connection for streaming
        %  audio data
        function status = isBinaryTransportUsed(obj)
            status = obj.UseBinaryTransport;
        end
    end
end