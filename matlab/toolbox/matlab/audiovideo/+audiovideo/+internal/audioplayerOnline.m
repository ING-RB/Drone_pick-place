classdef (CaseInsensitiveProperties=true, TruncatedProperties=true) ...
        audioplayerOnline < audiovideo.internal.Iaudioplayer
    %

    %   audioplayerOnline Audio player object.
    %
    %   audioplayerOnline(Y, Fs) creates an audioplayerOnline object for
    %   signal Y, using sample rate Fs.  A handle to the object is
    %   returned.
    %
    %   audioplayerOnline(Y, Fs, NBITS, ID) creates an audioplayerOnline
    %   object using audio device identifier ID for output.  If ID equals
    %   -1 the default output device will be used. Note that the value of
    %   NBITS is ignored.
    %
    %
    % audioplayerOnline Methods:
    %   get          - Query properties of audioplayerOnline object.
    %   isplaying    - Query whether playback is in progress.
    %   pause        - Pause playback.
    %   play         - Play audio from beginning to end.
    %   playblocking - Play, and do not return control until playback
    %                  completes.
    %   resume       - Restart playback from paused position.
    %   set          - set properties of audioplayerOnline object.
    %   stop         - stop playback.
    %
    % audioplayerOnline Properties:
    %   BitsPerSample    - Number of bits per sample. (Read-only)
    %   CurrentSample    - Current sample that the audio output device
    %                      is playing. If the device is not playing,
    %                      CurrentSample is the next sample to play with
    %                      play or resume. (Read-only)
    %   DeviceID         - Identifier for audio device. (Read-only)
    %   NumChannels      - Number of audio channels. (Read-only)
    %   Running          - Status of the audio player: 'on' or 'off'.
    %                      (Read-only)
    %   SampleRate       - Sampling frequency in Hz.
    %   TotalSamples     - Total length of the audio data in samples.
    %                      (Read-only)
    %   Tag              - String that labels the object.
    %   Type             - Name of the class: 'audioplayer'. (Read-only)
    %   UserData         - Any type of additional data to store with
    %                      the object.
    %   StartFcn         - Function to execute one time when playback starts.
    %   StopFcn          - Function to execute one time when playback stops.
    %   TimerFcn         - Function to execute repeatedly during playback.
    %                      To specify time intervals for the repetitions,
    %                      use the TimerPeriod property.
    %   TimerPeriod      - Time in seconds between TimerFcn callbacks.
    %
    % Example:
    %
    %       % Load snippet of Handel's Hallelujah Chorus and play back
    %       % only the first three seconds.
    %       load handel;
    %       p = audioplayerOnline(y, Fs);
    %       play(p, [1 (get(p, 'SampleRate') * 3)]);
    %
    % See also AUDIORECORDER, AUDIODEVINFO, AUDIOPLAYER/GET,
    %          AUDIOPLAYER/SET.

    % Copyright 2003-2024 The MathWorks, Inc.
    %

    % --------------------------------------------------------------------
    % General properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='public')
        SampleRate              % Sampling frequency in Hz.
    end

    properties(GetAccess='public', SetAccess='private')
        DeviceID                % ID of the Device to be used for playback
    end

    % --------------------------------------------------------------------
    % Internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private', Hidden)
        InternalDeviceID            % Actual ID of the Device passed to the API
        UUID                        % Unique ID for each audioplayer object
        PlayDoneEventSubscriber     % Subscriber for playback done event
        PlayStartEventSubscriber    % Subscriber for playback start event
        ConnectionStatus            % Keeps track of audio output device connection status. It can be empty if the connection with the device is unsuccessful or if browser refresh has taken place
        ObjCreated                  % Indicates whether the object was successfully created
        HasNewData                  % Flag for listening to subscribed events
        Timeout = 5                 % Timeout = 5 sec

        NumBytes = 4                % The number of bytes that are going to be required to store one sample of audio data, for "single" datatype its 4
        MaxByteLimit = 1e6          % Stores the maximum size of 1 packet of audio data, currently 1MB

        % JS Client will publish the corresponding statuses on the following channels so that MATLAB can read them and respond accordingly
        ConnectionStatusChannel     % Status of connection to audio output device
        PlayStartedChannel          % Play started status
        PlayEndedChannel            % Play ended status
        PlayingStatusChannel        % Current playing status, related to isplaying() method
        CurrentSampleValueChannel   % For getting the sample that is currently being played, related to get.CurrentSample() method
        DataReceivedChannel         % Client has received the transmitted audio data packet and is ready to receive the next one
    end

    % Properties for handling Binary Transport communication
    properties(Access=private)
        % Binary Stream names have to be alphanumeric ([_:-] are also allowed)
        StreamingChannelPrefix = "audioplayerStreaming"

        % Because of dynamic changes and the variables not being updated
        % correctly with loading of objects, etc. this Channel will contain
        % the final dynamic channel name whereas the Prefix will contain
        % the static element of the channel name
        StreamingChannel

        % Backup streaming channel where audio data will be transmitted via
        % MessageService in case Binary Transport fails
        BackupStreamingChannelPrefix = "/audioplayer/backupAudioStreaming"

        % Because of dynamic changes and the variables not being updated
        % correctly with loading of objects, etc. this Channel will contain
        % the final dynamic channel name whereas the Prefix will contain
        % the static element of the channel name
        BackupStreamingChannel

        % Flag to indicate whether Binary Transport or MessageService is
        % being used for audio data transmission
        UseBinaryTransport = true

        % Field to store a reference to the Binary Stream that will be used
        % for sending audio data
        BinaryChannelHandle

        % Channel where Client posts the status of whether it was able to
        % connect to the Binary Transport channel or not
        ClientBinaryTransportStatusChannel
    end

    properties(GetAccess=public, SetAccess=private, Hidden)
        % When Client posts status on ConnectionStatus channel, the
        % associated callback sets this flag to true so that the "waitfor"
        % call terminates appropriately
        ConnectionStatusReceived = false

        % When Client posts status on the ClientBinaryTransportStatus channel, the
        % associated callback sets this flag to true so that the "waitfor"
        % call terminates appropriately
        ClientBinaryTransportStatusReceived = false

        % When Client posts status on the DataReceived channel, the
        % associated callback sets this flag to true so that the "waitfor"
        % call terminates appropriately
        DataReceived = false
    end

    % --------------------------------------------------------------------
    % Playback properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='protected', Dependent)
        CurrentSample           % Current sample number being played
    end

    % --------------------------------------------------------------------
    % Non persistent, internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private', Transient)
        StartIndex              % Starting point of the Audio Sample being played
        EndIndex                % Ending point of the Audio Sample being played
        HasNoAudio              % Indicates if any audio device has been found
        audioRefreshListener    % Listens to the reconnectWithDevice event in case of browser refresh
        HasBrowserRefreshed     % Indicates if browser refresh has happened
    end


    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Access='public')
        function obj = audioplayerOnline(varargin)

            % Ensure the connector service is up and running
            connector.ensureServiceOn();

            obj@audiovideo.internal.Iaudioplayer(varargin{:});

            narginchk(1,4);
            obj.DeviceID = obj.DefaultDeviceID;

            fromaudiorecorder = isa(varargin{1}, 'audiorecorder');
            fromaudiorecorderInternal = isa(varargin{1},'audiovideo.internal.audiorecorderOnline');

            % Section to extract audio data from the input given

            % If the Argument 1 is an audiorecorder object.
            if fromaudiorecorder
                error(message('MATLAB:audiovideo:audioplayer:unsupportedAudioRecorder'));
            elseif fromaudiorecorderInternal
                recorder = varargin{1};
                obj.BitsPerSample = get(recorder, 'BitsPerSample');
                % In case recorder is empty, use a try-catch.
                try
                    switch obj.BitsPerSample
                        case 8
                            signal = getaudiodata(recorder, 'uint8');
                        case 16
                            signal = getaudiodata(recorder, 'int16');
                        case 24
                            signal = getaudiodata(recorder, 'double');
                        otherwise
                            error(message('MATLAB:audiovideo:audioplayer:invalidbitpersample'));
                    end

                    obj.SampleRate = get(recorder, 'SampleRate');
                catch exception
                    throw(exception);
                end
            else % Signal doesn't come from audiorecorder.
                narginchk(2,4);

                try
                    obj.checkNumericArgument(varargin{:});
                    signal = varargin{1};
                    obj.SampleRate = varargin{2};
                    if(nargin >= 3)
                        obj.BitsPerSample = varargin{3};
                    else
                        obj.BitsPerSample = obj.getBitsPerSampleForThisSignal(signal);
                    end

                    if(nargin == 4)
                        obj.DeviceID = varargin{4};
                    end
                catch exception
                    throw(exception);
                end
            end

            obj.AudioData = signal;

            obj.initialize();
        end

        function play(obj, varargin)
            %PLAY Plays audio samples in audioplayerOnline object.
            %
            %   PLAY(OBJ) plays the audio samples from the beginning.
            %
            %   PLAY(OBJ, START) plays the audio samples from the START sample.
            %
            %   PLAY(OBJ, [START STOP]) plays the audio samples from the START sample
            %   until the STOP sample.
            %
            %   Use the PLAYBLOCKING method for synchronous playback.
            %
            % Example:  Load snippet of Handel's Hallelujah Chorus and play back
            %           only the first three seconds.
            %
            %   load handel;
            %   p = audioplayerOnline(y, Fs);
            %   play(p, [1 (get(p, 'SampleRate') * 3)]);
            %
            % See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %          AUDIOPLAYER/SET, AUDIOPLAYER/PLAYBLOCKING.

            if obj.hasNoAudioHardware()
                return;
            end

            % If more than two arguments are specified, error is thrown
            narginchk(1,2);

            % Return if the player is 'On'
            if obj.isplaying()
                return;
            end

            if obj.HasBrowserRefreshed
                % If browser has been refreshed, we need to reconnect with
                % the device before playback
                obj.HasBrowserRefreshed = false;
                obj.createConnection();
            end

            % Track the start and end indices of the current playback.
            startIndex = 1;
            endIndex = obj.TotalSamples;

            if ~isempty(varargin)
                % Check there are at most two arguments in Index vector and they are
                % numeric
                if (nargin == 2) && ...
                        (~isnumeric(varargin{1}) || ...
                        (numel(varargin{1}) > 2 ) || ...
                        (isempty(varargin{1})))
                    error(message('MATLAB:audiovideo:audioplayer:invalidIndex'));
                end
                % Second elements of the vector specifies the upper bound of the
                % sample being played.
                if size(varargin{1}, 2) == 2
                    % Syntax used is play(obj, [start stop])
                    startIndex = varargin{1}(1);
                    endIndex = varargin{1}(2);
                else
                    % Play from the indexed position to the end of the file.
                    % Syntax used is play(obj, start)
                    startIndex = varargin{1}(1);
                    endIndex = obj.TotalSamples;
                end

                if startIndex <= 0 ||  startIndex >= endIndex || endIndex > obj.TotalSamples
                    warning(message('MATLAB:audiovideo:audioplayer:invalidselection'));
                    startIndex = 1;
                    endIndex = obj.TotalSamples;
                end
            end

            obj.StartIndex = startIndex;
            obj.EndIndex = endIndex;

            dataStruct.StartIndex = startIndex;
            dataStruct.EndIndex = endIndex;
            dataStruct.UUID = obj.UUID;

            % initialize the Timer if needed
            obj.initializeTimer();
            % Execute StartFcn
            internal.Callback.execute(obj.StartFcn, obj);

            % Subscribe to /audio/audioPlayStarted channel before
            % publishing message for play
            obj.callStartTimer();
            message.publish('/audio/play', dataStruct);
        end

    end

    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence. Forward Declaration.
        %------------------------------------------------------------------
        function obj = loadobj(B)
            %LOADOBJ Load function for audioplayerOnline objects.
            %
            %    OBJ = LOADOBJ(B) is called by LOAD when an audioplayerOnline object is
            %    loaded from a .MAT file. The return value, OBJ, is subsequently
            %    used by LOAD to populate the workspace.
            %
            %    LOADOBJ will be separately invoked for each object in the .MAT file.
            %
            %    See also AUDIOPLAYER/SAVEOBJ.

            % If we're on UNIX and don't have Java, warn and return.

            if isfield(B, 'internalObj')
                savedObj = struct(B);
                props = savedObj.internalObj;
                signal = savedObj.signal;

                obj = audioplayerOnline(signal, props.SampleRate, props.BitsPerSample, ...
                    props.DeviceID);

                % Set the original settable property values.
                propNames = getSettableProperties(obj);

                for i = 1:length(propNames)
                    try
                        set(obj, propNames{i}, props.(propNames{i}));
                    catch %#ok<CTCH>
                        warning(message('MATLAB:audiovideo:audioplayer:couldnotset', propNames{ i }));
                    end
                end
            else
                % The status flags are set back to null values so that the
                % createConnection() call made as part of the refresh event
                % communicates with the JS client appropriately and does not
                % skip any checks
                % Note: If you add any more status flag checks for
                % communication, they have to be cleared here, otherwise
                % refresh will not be compatible with "audioplayer"
                B.ConnectionStatus = [];
                B.ConnectionStatusReceived = [];
                B.ClientBinaryTransportStatusReceived = [];
                B.initialize();
                obj = B;
            end
        end

        function audioRefresh()
            % This static method is called when the browser is refreshed in
            % MATLAB Online

            % Notify all existing audioplayerOnline objects
            instance = audiovideo.internal.audioplayerrecorderOnlineBrowserRefresh.Instance;
            instance.notifyAllAudioPlayerRecorderOnline();
        end

    end

    methods(Access='private')
        function initialize(obj)
            % This method initializes metadata related to the "audioplayer"
            % object, its channels, the Binary Transport handle and calls the
            % createConnection() method
            if obj.hasNoAudioHardware()
                return;
            end

            obj.InternalDeviceID = audiovideo.internal.audio.utility.getInternalDeviceIDFromID(...
                audiovideo.internal.AudioDeviceTypeEnums.OutputDevice, obj.DeviceID);

            obj.AudioDataType = class(obj.AudioData);

            % Initialize other documented/Hidden/un-documented properties
            obj.NumChannels = size(obj.AudioData,2);

            % Create unique ID for each audioplayer object
            obj.UUID = matlab.lang.internal.uuid;

            obj.HasBrowserRefreshed = false;

            % Attach the listener to "reconnectWithDevice" event in case of
            % Browser Refresh
            instance = audiovideo.internal.audioplayerrecorderOnlineBrowserRefresh.Instance;
            obj.audioRefreshListener = event.listener(instance, 'reconnectWithDevice', ...
                @(eventObj, source) onBrowserRefresh(obj));

            % Setting up audio channels using the "audioplayer" UUID
            moAudioChannel = '/audio/' + obj.UUID;
            obj.ConnectionStatusChannel         = moAudioChannel + '/audioConnectionStatus';
            obj.PlayStartedChannel        = moAudioChannel + '/audioPlayStarted';
            obj.PlayEndedChannel          = moAudioChannel + '/audioPlayEnded';
            obj.PlayingStatusChannel      = moAudioChannel + '/audioPlayingStatus';
            obj.CurrentSampleValueChannel = moAudioChannel + '/currentSampleValue';
            obj.DataReceivedChannel = moAudioChannel + '/audioDataReceived';

            obj.ClientBinaryTransportStatusChannel = moAudioChannel + '/clientBinaryTransportStatus';

            obj.StreamingChannel = obj.StreamingChannelPrefix + "_" + obj.UUID;
            obj.BackupStreamingChannel = obj.BackupStreamingChannelPrefix + "/" + obj.UUID;

            % Create binary transport connection for streaming audio data
            obj.BinaryChannelHandle = connector.internal.binary.BinaryStream(char(obj.StreamingChannel));

            obj.createConnection();
        end

        function clientSwitchToMsgService(obj, switchToMsgServiceStatus)
            % This method is called when the Binary Transport connection fails or
            % the Binary Transport send() method fails in which case, the
            % "UseBinaryTransport" flag is set to false to indicate that
            % MessageService is being used for transfer of audio data

            % Delete the BinaryChannelHandle so that the stream is
            % terminated from MATLAB side, because once we switch to
            % MessageService, we are not switching back
            % Also, Binary Transport shouldn't try reconnecting from the JS
            % side, this accomplishes that
            delete(obj.BinaryChannelHandle);

            obj.UseBinaryTransport = ~switchToMsgServiceStatus;
        end

        function streamData(obj, audioDataAsSingle)
            % This method is used to send the audio data to the JS Client and
            % it uses the "UseBinaryTransport" flag to determine whether Binary
            % Transport or MessageService is to be used
            if (obj.UseBinaryTransport)
                try
                    obj.BinaryChannelHandle.send(audioDataAsSingle);
                catch
                    % Fallback to message service if binary transport fails
                    clientSwitchToMsgService(obj, true);

                    % Call the streamData() function again so that
                    % streaming is now done via MessageService
                    obj.streamData(audioDataAsSingle);
                end
            else
                % Use MessageService to publish audio data on the backup
                % streaming channel
                message.publish(obj.BackupStreamingChannel, audioDataAsSingle);
            end

        end

        function createConnection(obj)
            % This method publishes the "audioplayer" object's metadata to the JS Client and
            % waits till a connection is made to the audio output device by the JS Client.
            % It then streams the audio data to the JS Client via the streamData().
            if obj.hasNoAudioHardware()
                return;
            end

            % Extract metadata fields from the "audioplayer" object
            % and save it in dataStruct
            dataFieldnames  = {'UUID', 'SampleRate', 'NumChannels', 'InternalDeviceID', 'TotalSamples'};
            for fn = dataFieldnames
                dataStruct.(fn{1}) = obj.(fn{1});
            end

            % Subscription to the Connection Status channel
            subConnectionStatus = message.subscribe(obj.ConnectionStatusChannel, @(msg)audioConnectionStatus(msg));

            % Subscription to the Client Binary Transport Status channel
            subClientBinaryTransportStatus = message.subscribe(obj.ClientBinaryTransportStatusChannel, @(msg)clientBinaryTransportStatusCallback(msg));

            % Subscription to the Data Received channel
            subDataReceived = message.subscribe(obj.DataReceivedChannel, @(dataReceivedStatus)audioDataReceived(dataReceivedStatus));

            % Compute metadata required for packet-based transmission

            % "single" datatype occupies 4 bytes in memory
            numBytes = 4;
            totalBytes = obj.TotalSamples * obj.NumChannels * numBytes;

            % Transmitting packets of size 1MB each
            maxByteLimit = 1e6;

            totalPackets = ceil(totalBytes/maxByteLimit);

            numSamplesPerPacket = round(obj.TotalSamples/totalPackets);

            % Attaching the "numSamplesPerPacket" attribute in dataStruct
            % so that it can be communicated to the JS Client for
            % appropriate processing
            dataStruct.SamplesPerPacket = numSamplesPerPacket;
            % Flag to check the browser compatibility
            isBrowserSupported = true;
            % Publish the UUID and other metadata of the "audioplayer" object to the
            % MediaCapture and Streams API at the JS side to establish a connection.
            message.publish('/audio/createConnection', dataStruct);
            % Wait till a response is received from the JS side on the
            % ConnectionStatus Channel, which means the
            % ConnectionStatusReceived flag will be set to true
            waitfor(obj, "ConnectionStatusReceived", true);
            message.unsubscribe(subConnectionStatus);
            % If browser is supported binary channel will be created from
            % the JS side, which means the ClientBinaryTransportStatusReceived
            % flag will be set to true
            if isBrowserSupported
                % Wait till client binary transport connection is ready
                waitfor(obj, "ClientBinaryTransportStatusReceived", true);
            end

            message.unsubscribe(subClientBinaryTransportStatus);

            % Callback that is executed when JS sends a response on the
            % ConnectionStatus channel, this will enable MATLAB to proceed
            % further with "audioplayer" creation
            function audioConnectionStatus(msg)
                % Check if any error message has been sent on ConnectionStatus Channel
                % from JS side
                if ischar(msg)
                    % If the received message is a char, it indicates an issue.
                    % Currently, we interpret any char message as a browser compatibility issue.
                    isBrowserSupported = false;
                end
                % Mark that a connection status message has been received.
                obj.ConnectionStatusReceived = true;
                obj.ObjCreated = msg;
            end

            % Callback that is executed when JS sends a response on the
            % ClientBinaryTransportStatus channel, this will indicate
            % whether to use Binary Transport or MessageService
            function clientBinaryTransportStatusCallback(binaryTransportStatus)
                obj.ClientBinaryTransportStatusReceived = true;
                obj.UseBinaryTransport = binaryTransportStatus;

                % If we are switching to MessageService, then delete the
                % handle to terminate the Binary Transport connection at
                % the MATLAB side
                if (~obj.UseBinaryTransport)
                    delete(obj.BinaryChannelHandle);
                end
            end

            % Callback that is executed when JS sends on a response on the
            % DataReceived channel, this will indicate whether the client
            % is ready to receive the next packet or not
            function audioDataReceived(dataReceivedStatus)
                obj.DataReceived = dataReceivedStatus;
            end

            if ischar(obj.ObjCreated)
                if  strcmp(obj.ObjCreated,message('MATLAB:audiovideo:audioplayer:BrowserSupport').getString)
                 throwAsCaller(MException('MATLAB:audiovideo:audioplayer:BrowserSupport',obj.ObjCreated));
                else
                % there is an error in object construction
                throwAsCaller(MException('MATLAB:audiovideo:audioplayer:cannotCreateObject', ...
                    extractAfter(obj.ObjCreated, ': ')));
                 end
            elseif ~obj.ObjCreated
                throwAsCaller(MException('MATLAB:audiovideo:audioplayer:cannotCreateObject'));
            else
                % device connection successful
                obj.ConnectionStatus = true;
            end

            % Convert audio data to single in order to save up on the
            % amount of data that is transmitted to the JS side in exchange
            % for loss in precision of the data
            audioDataAsSingle = toSingle(obj.AudioData);

            % For loop that transmits 1 audio data packet of size utmost
            % 1MB in each iteration
            for numPackets = 1:totalPackets
                startingSampleIndex = (numPackets - 1) * numSamplesPerPacket + 1;
                if numPackets == totalPackets
                    endingSampleIndex = obj.TotalSamples;
                else
                    endingSampleIndex = numPackets * numSamplesPerPacket;
                end

                % Send the current packet's audio data to the JS Client
                dataToSend = audioDataAsSingle(startingSampleIndex:endingSampleIndex,:);
                obj.streamData(dataToSend);

                % Wait till client is ready to receive the next packet
                waitfor(obj, "DataReceived", true);

                % Set DataReceived back to false so that the next iteration
                % progresses synchronously
                obj.DataReceived = false;
            end

            message.unsubscribe(subDataReceived);

            % Publish the UUID of the "audioplayer" object on the
            % dataComplete channel so that Client knows that all packets
            % have been transmitted and it can start initializing the
            % AudioBuffer
            message.publish('/audio/dataComplete', obj.UUID);

            function output = toSingle( data )
                switch(class(data))
                    case 'single'
                        output = data;
                    case 'double'
                        output = single(data);
                    case 'int8'
                        output = single(data)/(2^(8-1));
                    case 'int16'
                        output = single(data)/(2^(16-1));
                    case 'uint8'
                        output = single(data)/2^(8-1) - 1.0;
                end
            end
        end

        function startTimerToListenSubMessage(obj, sub)
            % Once it is verified that "waitfor" can handle signal
            % transmissions without performance issues, this function can
            % be removed and instead the "Received" flags can be used along
            % with "waitfor" to implement message acknowledgements

            % This function executes a timer function every 0.5 seconds on
            % the specified subscription channel in order to check whether
            % obj.HasNewData is set to true or not.
            % However if the wait time is greater than 5 seconds it will
            % timeout with an error
            obj.HasNewData = false;
            t = timer('Period',0.5,'ExecutionMode','fixedRate','TimerFcn',@checkIfDataReceived);
            t.TasksToExecute = round(obj.Timeout/ t.Period);

            start(t);
            wait(t);    % audio wont return until the timer has elapsed

            % Time out if wait time is greater than 5 seconds
            if  ~obj.HasNewData
                message.unsubscribe(sub);
                error('MATLAB:audioplayer:timeout', message('MATLAB:audiovideo:audioplayer:timeout').getString);
            end

            delete(t);

            % If HasNewData is set to true, stop the timer and return
            function checkIfDataReceived(mTimer, ~)
                if obj.HasNewData
                    stop(mTimer);
                end
            end
        end

        function noAudio = hasNoAudioHardware(obj)
            % hasNoAudioHardware() returns a boolean based on whether any audio
            % output device is found.

            % Return if default device is being used to prevent enumerating
            % audio devices and prompting for microphone permission (g2275887)
            if obj.DeviceID == obj.DefaultDeviceID
                noAudio = false;
                return;
            end

            if isempty(obj.HasNoAudio)
                % Are there any audio outputs?
                [~, ~, audioOutputDeviceID, errorMsg] = audiovideo.internal.audio.utility.enumerateAudioOutputDevicesOnBrowser;

                if ~isempty(errorMsg)
                    throwAsCaller(MException('MATLAB:audiovideo:audioplayer:noAudioOutputDevice', errorMsg));
                end

                outputInfos = numel(audioOutputDeviceID);

                % Cache the value here to make subsequent calls faster.
                obj.HasNoAudio = (outputInfos == 0);
            end

            noAudio = obj.HasNoAudio;

            if (noAudio)
                % Warn here instead of erroring to support running on systems
                % with no audio outputs
                warning(message('MATLAB:audiovideo:audioplayer:noAudioOutputDevice'));
                return;
            end
        end

        function onBrowserRefresh(obj)
            % Method that is called when the browser is refreshed

            % Make sure in case of browser refresh, the previous playback of
            % the object is done and timer is cleaned up
            obj.audioPlayEnded();

            % The status flags are set back to null values so that the
            % createConnection() call made as part of the refresh event
            % communicates with the JS client appropriately and does not
            % skip any checks
            % Note: If you add any more status flag checks for
            % communication, they have to be cleared here, otherwise
            % refresh will not be compatible with "audioplayer"
            obj.ConnectionStatus = [];
            obj.ConnectionStatusReceived = [];
            obj.ClientBinaryTransportStatusReceived = [];
            obj.DataReceived = [];

            obj.HasBrowserRefreshed = true;

            % Refresh audio device cache
            audiovideo.internal.audio.utility.resetAudioDevices;
        end
    end

    methods(Access='protected')
        function cleanUp(obj)
            if isempty(obj.ConnectionStatus)
                % obj may be partially initialized due to an error in the
                % constructor
                return;
            end

            stop(obj);

            % Stop any previous playback of the object and clean up timer
            obj.audioPlayEnded();

            % delete the audioplayer object at client's side
            message.publish('/audio/delete', obj.UUID);
        end
    end

    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods
        function set.DeviceID(obj, value)
            import audiovideo.internal.audio.utility

            if ~(isscalar(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audioplayer:nonscalarDeviceID'));
            end
            % Return if default device is being used to prevent enumerating
            % audio devices and prompting for microphone permission (g2275887)
            if value == obj.DefaultDeviceID
                obj.DeviceID =  value;
                return;
            end

            % Get the list of all audio devices.
            [~, audioOutputDeviceList, ~, audioInputDeviceList,~,errorMsg] = utility.enumerateAudioDevicesOnBrowser;
            if ~isempty(errorMsg)
                throwAsCaller(MException('MATLAB:audiovideo:audioplayer:noAudioOutputDevice', errorMsg));
            end

            % Find total number of unique input devices
            uniqueInputDevicesCount = sum(utility.getIsDeviceUnique(audioInputDeviceList));

            % Find total number of unique output devices
            uniqueOutputDevicesCount = sum(utility.getIsDeviceUnique(audioOutputDeviceList));

            % Output device IDs start after input device IDs.
            % Input device IDs  - [0 : uniqueInputDevicesCount-1]
            % Output device IDs - [uniqueInputDevicesCount : TotalUniqueDeviceCount-1]
            outputIDs = uniqueInputDevicesCount : (uniqueInputDevicesCount+uniqueOutputDevicesCount)-1;

            if ~ismember(value, outputIDs)
                error(message('MATLAB:audiovideo:audioplayer:invaliddeviceID'));
            end

            obj.DeviceID = value;
        end

        function set.SampleRate(obj, value)
            % check for valid sample rate
            if ~(isscalar(value) && isnumeric(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audioplayer:nonscalarSampleRate'));
            end

            if ~isempty(obj.ConnectionStatus)
                error(message('MATLAB:audiovideo:audioplayer:changingSampleRate'));
            end

            obj.SampleRate = value;
        end


        function value = get.CurrentSample(obj)
            if isempty(obj.ConnectionStatus)
                value = [];
                return;
            end

            sub = message.subscribe(obj.CurrentSampleValueChannel, @(msg)currentSampleValue(msg));
            message.publish('/audio/currentSample', obj.UUID);

            obj.startTimerToListenSubMessage(sub);
            message.unsubscribe(sub);

            function currentSampleValue(msg)
                value = msg;
                obj.HasNewData = true;
            end
        end

    end

    %----------------------------------------------------------------------
    % Function Callbacks/Helper Functions
    %----------------------------------------------------------------------
    methods(Access='private')
        % Method that is called whenever audio play is about to be started
        % (play/resume), so that the subscription to PlayStarted and
        % PlayEnded channels are done
        function callStartTimer(obj)
            obj.PlayStartEventSubscriber = message.subscribe(obj.PlayStartedChannel, @(msg)obj.audioPlayStarted(msg));
            obj.PlayDoneEventSubscriber = message.subscribe(obj.PlayEndedChannel, @(msg)obj.audioPlayEnded());
        end

        % Callback triggered on a receive at the "PlayStartedChannel"
        function audioPlayStarted(obj, msg)
            message.unsubscribe(obj.PlayStartEventSubscriber);
            if msg
                startTimer(obj);
            else
                % audio playback was unsuccessful
                throwAsCaller('MATLAB:audiovideo:audioplayer:unableToPlayAudio');
            end
        end

        % Callback triggered on a receive at the "PlayEndedChannel"
        function audioPlayEnded(obj)
            if ~isempty(obj.PlayDoneEventSubscriber)
                message.unsubscribe(obj.PlayDoneEventSubscriber);
                obj.PlayDoneEventSubscriber = [];

                % Stop and un-initialize the timer if needed
                obj.stopTimer();
                obj.uninitializeTimer();

                internal.Callback.execute(obj.StopFcn, obj);
            end

        end
    end

    methods(Access='private')
        % Returns a list of publicly settable properties
        function settableProps = getSettableProperties(obj)
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
    % audioplayerOnline Functions
    %----------------------------------------------------------------------
    methods(Access='public')

        function status = isplaying(obj)
            %ISPLAYING Indicates if playback is in progress.
            %
            %    STATUS = ISPLAYING(OBJ) returns true or false, indicating
            %    whether playback is or is not in progress.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET.
            if isempty(obj.ConnectionStatus)
                status = false;
                return;
            end

            sub = message.subscribe(obj.PlayingStatusChannel, @(msg)audioPlayingStatus(msg));
            message.publish('/audio/isPlayOn', obj.UUID);

            obj.startTimerToListenSubMessage(sub);
            message.unsubscribe(sub);

            function audioPlayingStatus(msg)
                status = msg;
                obj.HasNewData = true;
            end
        end

        function stop(obj)
            %STOP Stops playback in progress.
            %
            %    STOP(OBJ) stops the current playback.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET, AUDIOPLAYER/PLAY, AUDIOPLAYER/PLAYBLOCKING,
            %             AUDIOPLAYER/PAUSE, AUDIOPLAYER/RESUME
            if obj.hasNoAudioHardware()
                return;
            end

            if obj.HasBrowserRefreshed
                return;
            end

            message.publish('/audio/stop', obj.UUID);
        end

        function pause(obj)
            %PAUSE Pauses playback in progress.
            %
            %    PAUSE(OBJ) pauses the current playback.  Use RESUME
            %    or PLAY to resume playback.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET, AUDIOPLAYER/RESUME,
            %             AUDIOPLAYER/PLAY.
            if obj.hasNoAudioHardware()
                return;
            end

            if ~obj.isplaying()
                return;
            end

            message.publish('/audio/pause', obj.UUID);
        end

        function resume(obj)
            %RESUME Resumes paused playback.
            %
            %    RESUME(OBJ) continues playback from paused location.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET, AUDIOPLAYER/PAUSE.
            if obj.hasNoAudioHardware()
                return;
            end

            if obj.HasBrowserRefreshed
                return;
            end

            if obj.isplaying()
                return;
            end

            % initialize the Timer if needed
            obj.initializeTimer();
            % Execute StartFcn
            internal.Callback.execute(obj.StartFcn, obj);

            % Subscribe to /audio/audioPlayStarted channel before
            % publishing message for resume
            obj.callStartTimer();
            message.publish('/audio/resume', obj.UUID);
        end


        function playblocking(obj, varargin)
            %PLAYBLOCKING Synchronous playback of audio samples in audioplayerOnline object.
            %
            %    PLAYBLOCKING(OBJ) plays from beginning; does not return until
            %                      playback completes.
            %
            %    PLAYBLOCKING(OBJ, START) plays from START sample; does not return until
            %                      playback completes.
            %
            %    PLAYBLOCKING(OBJ, [START STOP]) plays from START sample until STOP sample;
            %                      does not return until playback completes.
            %
            %    Use the PLAY method for asynchronous playback.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET, AUDIOPLAYER/PLAY.

            if obj.hasNoAudioHardware()
                return;
            end

            obj.play(varargin{:});

            % Wait till the last buffer has played till the end.
            while isplaying(obj)
                pause(0.01);
            end

            stop(obj);

        end

    end
end

% LocalWords:  Fs handel invalidbitpersample invalidselection couldnotset invaliddevice
