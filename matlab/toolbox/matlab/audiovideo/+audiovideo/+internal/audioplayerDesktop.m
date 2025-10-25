classdef audioplayerDesktop < audiovideo.internal.Iaudioplayer
    %audioplayerDesktop Audio player object.
    %   
    %   audioplayerDesktop(Y, Fs) creates an audioplayerDesktop object for signal Y, using
    %   sample rate Fs.  A handle to the object is returned.
    %
    %   audioplayerDesktop(Y, Fs, NBITS) creates an audioplayerDesktop object and uses NBITS
    %   bits per sample for floating point signal Y.  Valid values for NBITS
    %   are 8, 16, and 24.  The default number of bits per sample for floating
    %   point signals is 16.
    %
    %   audioplayerDesktop(Y, Fs, NBITS, ID) creates an audioplayerDesktop object using
    %   audio device identifier ID for output.  If ID equals -1 the default
    %   output device will be used.
    %
    %   audioplayerDesktop(R) creates an audioplayerDesktop object from AUDIORECORDER object R.
    %
    %   audioplayerDesktop(R, ID) creates an audioplayerDesktop object from AUDIORECORDER
    %   object R using audio device identifier ID for output.
    %
    % audioplayerDesktop Methods:
    %   get          - Query properties of audioplayerDesktop object.
    %   isplaying    - Query whether playback is in progress.
    %   pause        - Pause playback.
    %   play         - Play audio from beginning to end.
    %   playblocking - Play, and do not return control until playback
    %                  completes.
    %   resume       - Restart playback from paused position.
    %   set          - set properties of audioplayerDesktop object.
    %   stop         - stop playback.
    %
    % audioplayerDesktop Properties:
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
    %       p = audioplayerDesktop(y, Fs);
    %       play(p, [1 (get(p, 'SampleRate') * 3)]);
    %
    % See also AUDIORECORDER, AUDIODEVINFO, AUDIOPLAYER/GET,
    %          AUDIOPLAYER/SET.
    
    % Author(s): SM NH DTL
    % Copyright 2020-2022 The MathWorks, Inc.
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
    % Persistent internal properties
    % --------------------------------------------------------------------
    properties(GetAccess='private', SetAccess='private')
        HostApiID               % API ID for a particular driver model
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
        Channel                 % Sink for the audioplayerDesktop
        ChannelListener         % Listener for Channel events
        StartIndex              % Starting point of the Audio Sample being played
        EndIndex                % Ending point of the Audio Sample being played
        SamplesPlayed           % Number of samples sent to the Device
    end
    
    % --------------------------------------------------------------------
    % Constants
    % --------------------------------------------------------------------
    properties(Constant, GetAccess='protected')
        MinimumSampleRate  = 80
        MaximumSampleRate  = 1e6
        DesiredLatency     = 0.025 % Set the Latency (in seconds) we want the audio device to run at.
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
        function obj = audioplayerDesktop(varargin)
            obj@audiovideo.internal.Iaudioplayer(varargin{:});  
            
            narginchk(1,4);
            obj.DeviceID = obj.DefaultDeviceID;  
            
            fromaudiorecorder = isa(varargin{1}, 'audiovideo.internal.audiorecorderDesktop') || ...
                                isa(varargin{1}, 'audiorecorder');
            
            % If the Argument 1 is an audiorecorder object.
            if fromaudiorecorder
                % Audioplayer constructor with recorder taken at most 2
                % arguments.
                if(nargin > 2)
                    error(message('MATLAB:audiovideo:audioplayer:numericinputs'));
                end
                
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
                
                if(nargin == 2)
                    % Second argument should be DeviceID
                    % TODO: Yet to decide the DeviceID shift logic
                    if isnumeric(varargin{2})
                        obj.DeviceID = varargin{2};
                    else
                        error(message('MATLAB:audiovideo:audioplayer:invaliddeviceID'));
                    end
                end
                
            else % Signal doesn't come from audiorecorder.
                if(nargin == 1)
                    error(message('MATLAB:audiovideo:audioplayer:mustbeaudiorecorder'));
                end
                
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
            %PLAY Plays audio samples in audioplayerDesktop object.
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
            %   p = audioplayerDesktop(y, Fs);
            %   play(p, [1 (get(p, 'SampleRate') * 3)]);
            %
            % See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %          AUDIOPLAYER/SET, AUDIOPLAYER/PLAYBLOCKING.
            
            % SM
            % Copyright 2003-2016 The MathWorks, Inc.
            
            import audiovideo.internal.audio.Converter;
            
            if obj.hasNoAudioHardware()
                return;
            end
            
            % If more than two arguments are specified, error is thrown
            narginchk(1,2);
            
            % Return if the player is 'On'
            if obj.isplaying()
                return;
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
            
            % Any buffered data from previous play session should be cleaned
            % before sending the new data.
            obj.Channel.OutputStream.flush();
            
            % The number of samples sent to the audio device must be an exact multiple
            % of the buffer size. See g1130462 for details.
            bufferSize = double(Converter.secondsToSamples( obj.DesiredLatency,...
                obj.SampleRate ));
            samplesUntilDone = endIndex - startIndex + 1;
            extraSamples = rem(samplesUntilDone, bufferSize);
            actEndIndex = endIndex + bufferSize - extraSamples;
            
            obj.StartIndex = startIndex;
            
            % Due to the zero-padding being done, the number of samples played back is
            % more that what the user has requested. This is reflected in the EndIndex
            % property. Hence, obj.EndIndex - obj.StartIndex + 1 reflects the number of
            % samples in the signal + zero-padding samples (if any) that is played
            % back.
            obj.EndIndex = actEndIndex;
            
            % Feed Data to the asyncio Channel in chunks
            % Note: This is done instead of one call to OutputStream.write
            % to avoid extra memory usage while the OutputStream is segmenting
            % the audio and sending it to the device.
            curPos = obj.StartIndex;
            chunkSize = bufferSize * 100; % send 100 'buffers' at a time
            while(curPos <= obj.EndIndex)
                endChunk = curPos + chunkSize - 1;
                if endChunk > endIndex
                    % This code path is hit for the last chunk or buffer being played
                    % back.
                    % As the EndIndex property includes the padding to ensure a full
                    % buffer, copy only the suitable amount of data from that supplied
                    % by the user.
                    endChunk = obj.EndIndex;
                    dataToWrite = zeros( endChunk - curPos + 1, ...
                        obj.NumChannels, ...
                        class(obj.AudioData) );
                    dataToWrite(1:endIndex - curPos + 1, 1:obj.NumChannels) = ...
                        obj.AudioData(curPos:endIndex,1:obj.NumChannels);
                    
                    obj.Channel.OutputStream.write(dataToWrite, bufferSize);
                else
                    obj.Channel.OutputStream.write( ...
                        obj.AudioData(curPos:endChunk,1:obj.NumChannels), ...
                        bufferSize);
                end
                
                curPos = endChunk + 1;
            end
            
            obj.resume();
        end
    end

    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence.
        %------------------------------------------------------------------
        function obj = loadobj(B)
            %LOADOBJ Load function for audioplayerDesktop objects.
            %
            %    OBJ = LOADOBJ(B) is called by LOAD when an audioplayerDesktop object is
            %    loaded from a .MAT file. The return value, OBJ, is subsequently
            %    used by LOAD to populate the workspace.
            %
            %    LOADOBJ will be separately invoked for each object in the .MAT file.
            %
            %    See also AUDIOPLAYER/SAVEOBJ.
            
            %    SM
            %    Copyright 2003-2013 The MathWorks, Inc.
                        
            B.initialize();
            obj = B;            
        end
    end
    
    methods(Access='private')
        function initialize(obj)
            if obj.hasNoAudioHardware()
                return;
            end
            
            % Initialize other un-documented properties.
            
            % Grab the default device.
            obj.HostApiID = multimedia.internal.audio.device.HostApi.Default;
            
            obj.AudioDataType = class(obj.AudioData);
            
            % Initialize other documented/Hidden properties
            obj.NumChannels = size(obj.AudioData,2);
            obj.StartIndex = 1;
            
            % The number of samples sent to the audio device must be an
            % exact multiple of the buffer size. See g1130462 for details.
            endIndex = obj.TotalSamples;
            bufferSize = audiovideo.internal.audio.Converter.secondsToSamples(...
                                        obj.DesiredLatency, obj.SampleRate);
            extraSamples = rem(obj.TotalSamples, bufferSize);
            actEndIndex = endIndex + bufferSize - extraSamples;
            obj.EndIndex = actEndIndex;
            
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
                    StreamLimits = [0, Inf]);
            catch exception
                throw(obj.createDeviceException(exception));
            end
            
            
            obj.ChannelListener = event.listener(obj.Channel,'Custom', ...
               @(src,event)(obj.onCustomEvent(event)));
            
            % Never timout when waiting on the output stream
            obj.Channel.OutputStream.Timeout = Inf; 

        end
        
        function uninitialize(obj)
            obj.uninitializeTimer(); %make sure timer object is cleaned up   
            
            obj.Channel.close();

            delete(obj.ChannelListener);
            obj.ChannelListener = [];
        end
    end
    
    methods(Access='protected')
        function cleanUp(obj)
            if isempty(obj.Channel)
                % obj may be partially initialized during loadbobj,
                % or during an error in the constructor
                return; 
            end
            
            stop(obj);
            
            obj.uninitialize();
        end
    end
    
    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods
        function set.DeviceID(obj, value)
            if ~(isscalar(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audioplayer:nonscalarDeviceID'));
            end
            
            % Get the list of output devices
            deviceInfos = multimedia.internal.audio.device.DeviceInfo.getDevicesForDefaultHostApi;
            outputInfos = deviceInfos([deviceInfos.NumberOfOutputs] > 0);
            
            if ~(value==obj.DefaultDeviceID || ismember(value, [outputInfos.ID]))
                error(message('MATLAB:audiovideo:audioplayer:invaliddeviceID'));
            end
            
            obj.DeviceID = value;
        end
        
        function set.SampleRate(obj, value)
            % check for valid sample rate
            if ~(isscalar(value) && isnumeric(value) && ~isinf(value))
                error(message('MATLAB:audiovideo:audioplayer:nonscalarSampleRate'));
            end
                        
            if value < obj.MinimumSampleRate || value > obj.MaximumSampleRate
                error(message('MATLAB:audiovideo:audioplayer:invalidSampleRate', obj.MinimumSampleRate, obj.MaximumSampleRate));
            end
            
            sampleRateChanged = obj.SampleRate ~= value;
            obj.SampleRate = value;
            
            if obj.isplaying() && sampleRateChanged
                % Player is already playing. Stop it and restart it so
                % that new rate is passed down the channel to the device.
                pause(obj);
                
                % Get the Current Sample Before calling stop
                startPosition = obj.CurrentSample; %#ok<MCSUP>
              
                stop(obj);
                
                stopPosition = obj.EndIndex;
                if stopPosition > obj.TotalSamples
                    stopPosition = obj.TotalSamples;
                end
                play(obj, [startPosition stopPosition]); %#ok<MCSUP>
            end
        end
        
        
        function value = get.CurrentSample(obj)
            totalSamplesQueued = obj.EndIndex - obj.StartIndex + 1;
            
            if isempty(obj.Channel)
                % channel in the process of being initialized
                % (in initializeChannel function)
                dataSent = totalSamplesQueued; 
            else
                dataSent = totalSamplesQueued - obj.Channel.OutputStream.DataToSend;
            end
            
            if(dataSent >= totalSamplesQueued)
                % We always point to the next sample to be played. When we
                % are done playing, the next sample to be played is the 1st
                % sample.
                value = 1;
            else
                value = obj.StartIndex + dataSent;
            end
        end
        
        
        function value = get.Options(obj)
            import multimedia.internal.audio.device.DeviceInfo;
            import audiovideo.internal.audio.*;

            value.HostApiID = int32(obj.HostApiID);
            
            if obj.DeviceID == obj.DefaultDeviceID
                value.DeviceID = int32(DeviceInfo.getDefaultOutputDeviceID(obj.HostApiID));
            else
                value.DeviceID = int32(obj.DeviceID);
            end
           
            % OutputChannels is a vector of channel indices to playback 
            value.OutputChannels = int32(1:obj.NumChannels);
            value.SampleRate = uint32(obj.SampleRate);
            value.BufferSize = uint32(Converter.secondsToSamples(obj.DesiredLatency, obj.SampleRate));
            value.QueueDuration = uint32(computeQueueDuration(value.BufferSize));
            value.AudioDataType = obj.AudioDataType;
            value.BitsPerSample = uint32(obj.BitsPerSample);
            value.SamplesUntilDone = uint64(obj.EndIndex - obj.CurrentSample + 1);
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
        
        function noAudio = hasNoAudioHardware()
            persistent hasNoAudio;
            if ~isempty(hasNoAudio)
                noAudio = hasNoAudio;
            else
                % are there any audio outputs?
                deviceInfos = multimedia.internal.audio.device.DeviceInfo.getDevicesForDefaultHostApi;
                outputInfos = deviceInfos([deviceInfos.NumberOfOutputs] > 0);

                % Enumerating devices is expensive,
                % Cache the value here to make subsequent calls faster.
                hasNoAudio = isempty(outputInfos);
                
                noAudio = hasNoAudio;
            end
            
            if (noAudio)
                % Channel is not initialized, warn here instead of erring
                % to support running on systems with no audio outputs
                warning(message('MATLAB:audiovideo:audioplayer:noAudioOutputDevice'));
                return;
            end
        end
        
        function exceptionObj = createDeviceException(exception)
            msg = strrep(exception.message, 'PortAudio', 'Device');
            exceptionObj = MException('MATLAB:audiovideo:audioplayer:DeviceError', msg);
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
    % audioplayerDesktop Functions
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
            
            status = ~isempty(obj.Channel) && obj.Channel.isOpen();
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
            
            obj.Channel.OutputStream.flush();
            obj.pause();
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
            
            obj.Channel.close();
            
            % Stop and uninitialize the timer if needed
            obj.stopTimer();
            obj.uninitializeTimer();

            
            internal.Callback.execute(obj.StopFcn, obj);
            
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
            
            if obj.isplaying()
                return;
            end
            
            % If there is no data to send resume
            % from the beginning
            if (obj.Channel.OutputStream.DataToSend == 0)
                obj.play();
                return;
            end
            
            % initialize the Timer if needed
            % (timer will be started in onCustomEvent)
            obj.initializeTimer();
            
            
            % Execute StartFcn
            internal.Callback.execute(obj.StartFcn, obj);
            
            try
                obj.Channel.open(obj.Options);
            catch exception
                throw(obj.createDeviceException(exception));
            end
            
        end
        
        
        function playblocking(obj, varargin)
            %PLAYBLOCKING Synchronous playback of audio samples in audioplayerDesktop object.
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
            obj.Channel.OutputStream.drain();
            
            % Wait till the last buffer has played till the end.
            while isplaying(obj)
                pause(0.01);
            end
            
            stop(obj);
            
        end
        
    end
end
