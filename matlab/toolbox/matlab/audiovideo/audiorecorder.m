classdef (CaseInsensitiveProperties=true, TruncatedProperties=true) ...
        audiorecorder < matlab.mixin.SetGet & ...
        matlab.mixin.CustomDisplay
    %audiorecorder Audio recorder object.
    %   audiorecorder creates an 8000 Hz, 8-bit, 1 channel audiorecorder object.
    %   A handle to the object is returned.
    %
    %   audiorecorder(Fs, NBITS, NCHANS) creates an audiorecorder object with
%   sample rate Fs in Hertz, number of bits NBITS, and number of channels NCHANS. 
%   Common sample rates are 8000, 11025, 22050, 44100, 48000, and 96000 Hz.
%   The number of bits must be 8, 16, or 24. The number of channels must
%   be 1 or 2 (mono or stereo).
%
%   audiorecorder(Fs, NBITS, NCHANS, ID) creates an audiorecorder object using 
%   audio device identifier ID for input.  If ID equals -1 the default input 
%   device will be used.
%   
% audiorecorder Methods:
%   get            - Query properties of audiorecorder object.
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
%   set            - Set properties of audiorecorder object.
%   stop           - Stop recording.
%
% audiorecorder Properties:
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
% audiorecorder Properties (Deprecated):
%   NOTE: audiorecorder ignores any specified values for these properties, 
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
%     r = audiorecorder(22050, 16, 1);
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

%    Copyright 1984-2023 The MathWorks, Inc.
%       

    % --------------------------------------------------------------------
    % General properties 
    % --------------------------------------------------------------------
    properties(Dependent, GetAccess='public', SetAccess='private')
        SampleRate      % Sampling Frequency in Hz
        BitsPerSample   % Number of Bits per audio Sample
        NumChannels     % Number of audio channels recording
        DeviceID        % Identifier for audio device in use.
    end

    properties(GetAccess='public', SetAccess='private', Dependent)
        CurrentSample           % Current sample that the audio input device is recording
        TotalSamples            % Total length of the audio data in samples.
        Running                 % Status of the audio recorder: 'on' or 'off'.
    end
    
    properties(GetAccess='public', SetAccess='private', Dependent, Hidden)
        NumberOfChannels;       % Number of audio channels recording
    end

    % --------------------------------------------------------------------
    % Callback Properties
    % --------------------------------------------------------------------
    properties(Dependent, GetAccess='public', SetAccess='public')
        StartFcn                % Handle to a user-specified callback function that is executed once when playback stops.
        StopFcn                 % Handle to a user-specified callback function that is executed once when playback stops.
        TimerFcn                % Handle to a user-specified callback function that is executed repeatedly (at TimerPeriod intervals) during playback.
        TimerPeriod             % Time, in seconds, between TimerFcn callbacks.   
        Tag                     % User-specified object label string.
        UserData                % Some user defined data.
    end

    properties(Dependent, GetAccess='public', SetAccess='private', Transient)
        Type                    % For Backward compatibility
    end
    
    % --------------------------------------------------------------------
    % Unused Legacy Properties
    % These Properties are unused the current audiorecorder
    % But remain for backward compatibility.  These will be removed 
    % in a future release.
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='public', Hidden)
        BufferLength   = [];   % To be removed in a future release
        NumberOfBuffers = [];  % To be removed in a future release
    end
 

    properties(Access='private')
        audiorecorderImpl
    end

    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Access='public')
        function obj = audiorecorder(varargin)
            import matlab.internal.capability.Capability;
            % Create a audiorecorderDesktop object or audiorecorderOnline
            % object based on where this is running.
            try
                if Capability.isSupported(Capability.LocalClient)
                    obj.audiorecorderImpl = audiovideo.internal.audiorecorderDesktop(varargin{:});
                else
                    % This is running in MATLAB Online, create a
                    % audiorecorderOnline object.
                    obj.audiorecorderImpl = audiovideo.internal.audiorecorderOnline(varargin{:});
                end
            catch exception
                % If there were errors creating a audiorecorderOnline or
                % audiorecorderDesktop object, error out.
                throwAsCaller(exception);
            end
        end

        function delete(obj)
            %DELETE the object and perform cleanup.
            try
                delete(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end
        end

    end

    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence. Forward Declaration.
        %------------------------------------------------------------------
        function obj = loadobj(B)
            %LOADOBJ Load function for audiorecorder objects.
            %
            %    OBJ = LOADOBJ(B) is called by LOAD when an audiorecorder object is
            %    loaded from a .MAT file. The return value, OBJ, is subsequently
            %    used by LOAD to populate the workspace.
            %
            %    LOADOBJ will be separately invoked for each object in the .MAT file.
            %
            %    See also AUDIORECORDER/SAVEOBJ.
            
            %    SM

            if isprop(B, 'audiorecorderImpl')
                obj = B;
                return;
            end
            
            % If we're on UNIX and don't have Java, warn and return.
            if isfield(B, 'internalObj')
                savedObj = struct(B);
                props = savedObj.internalObj;
                
                % We renamed the NumberOfChannels property to NumChannels in
                % R2019a.
                if isfield(props, 'NumberOfChannels')
                    numChannels = props.NumberOfChannels;
                elseif isfield(props, 'NumChannels')
                    numChannels = props.NumChannels;
                end
                obj = audiorecorder(props.SampleRate, props.BitsPerSample, ...
                    numChannels, props.DeviceID);
                
                % Set the original settable property values.
                %propNames = fieldnames(set(obj));
                propNames = getSettableProperties(obj.audiorecorderImpl);
                
                for i = 1:length(propNames)
                    try
                        set(obj, propNames{i}, props.(propNames{i}));
                    catch %#ok<CTCH>
                        warning(message('MATLAB:audiovideo:audiorecorder:couldnotset', propNames{ i }));
                    end
                end
            end
        end
    end

    methods(Access='protected')
        function s = getFooter(~)
            % Add a footer note for MATLAB Online that BitsPerSample are
            % ignored
            import matlab.internal.capability.Capability;
            if Capability.isSupported(Capability.LocalClient)
                s = '';
            else
                % Display the footer in MATLAB online
                s = getString(message( 'MATLAB:audiovideo:audiorecorder:BitsPerSampleIgnored'));
            end
        end
    end

    methods(Hidden)
        % Get the status of binary transport connection for streaming audio
        % data
        function status = isBinaryTransportUsed(obj)
            status = obj.audiorecorderImpl.isBinaryTransportUsed();
        end
    end
    %----------------------------------------------------------------------
    % Custom Getters/Setters
    %----------------------------------------------------------------------
    methods

        function value = get.NumberOfChannels(obj)
            value = obj.audiorecorderImpl.NumChannels;
        end

        function value = get.NumChannels(obj)
            value = obj.audiorecorderImpl.NumChannels;
        end        

        function value = get.BitsPerSample(obj)
            value = obj.audiorecorderImpl.BitsPerSample;
        end        
        
        function value  = get.CurrentSample(obj)
            value = obj.audiorecorderImpl.CurrentSample;
        end

        function value  = get.DeviceID(obj)
            value = obj.audiorecorderImpl.DeviceID;
        end        
        
        function value = get.Running(obj)
            value = obj.audiorecorderImpl.Running;
        end

        function value = get.SampleRate(obj)
            value = obj.audiorecorderImpl.SampleRate;
        end        
        
        function value = get.TotalSamples(obj)
            value = obj.audiorecorderImpl.TotalSamples;
        end

        function value = get.Tag(obj)
            value = obj.audiorecorderImpl.Tag;
        end        

        function value = get.Type(obj)
            value = obj.audiorecorderImpl.Type;
        end    

        function value = get.UserData(obj)
            value = obj.audiorecorderImpl.UserData;
        end    

        function value = get.StartFcn(obj)
            value = obj.audiorecorderImpl.StartFcn;
        end

        function value = get.StopFcn(obj)
            value = obj.audiorecorderImpl.StopFcn;
        end        

        function value = get.TimerFcn(obj)
            value = obj.audiorecorderImpl.TimerFcn;
        end    

        function value = get.TimerPeriod(obj)
            value = obj.audiorecorderImpl.TimerPeriod;
        end   

        function set.BitsPerSample(obj, value)
            obj.audiorecorderImpl.BitsPerSample = value;
        end

        function set.DeviceID(obj, value)
            obj.audiorecorderImpl.DeviceID = value;
        end

        function set.SampleRate(obj, value)
            obj.audiorecorderImpl.SampleRate = value;
        end

        function set.NumChannels(obj, value)
           obj.audiorecorderImpl.NumChannels = value;
        end
        
        function set.NumberOfChannels(obj, value)
           obj.audiorecorderImpl.NumChannels = value;
        end
                
        function set.StartFcn(obj, value)
            obj.audiorecorderImpl.StartFcn = value;
        end
        
        function set.StopFcn(obj, value)
            obj.audiorecorderImpl.StopFcn = value;
        end
        
        function set.TimerFcn(obj, value)
            obj.audiorecorderImpl.TimerFcn = value;
        end
        
        function set.TimerPeriod(obj, value)
            obj.audiorecorderImpl.TimerPeriod = value;
         end
        
         function set.Tag(obj, value)
            obj.audiorecorderImpl.Tag = value;
         end

        function set.UserData(obj, value)
            obj.audiorecorderImpl.UserData = value;
        end         

    end
    
    %----------------------------------------------------------------------        
    % audiorecorder Functions
    %----------------------------------------------------------------------
    methods(Access='public')
        function c = horzcat(varargin)
            %HORZCAT Horizontal concatenation of audiorecorder objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audiorecorder:noconcatenation'));
            end
        end
        
        function c = vertcat(varargin)
            %VERTCAT Vertical concatenation of audiorecorder objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error(message('MATLAB:audiovideo:audiorecorder:noconcatenation'));
            end
        end
        
        function status = isrecording(obj)
            %ISRECORDING Indicates if recording is in progress.
            %
            %    STATUS = ISRECORDING(OBJ) returns true or false, indicating
            %    whether recording is or is not in progress.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET.

            try
                status = isrecording(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end         
        end

        function ap = getplayer(obj)
            %GETPLAYER Gets associated audioplayer object.
            %
            %    GETPLAYER(OBJ) returns the audioplayer object associated with
            %    this Iaudiorecorder object.
            %
            %    See also AUDIORECORDER, AUDIOPLAYER.

            try
                ap = getplayer(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end
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

            try
                stop(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end
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
            
            try
                pause(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end
        end
        
        function resume(obj)
            %RESUME Resumes paused recording.
            %
            %    RESUME(OBJ) continues recording from paused location.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/GET,
            %             AUDIORECORDER/SET, AUDIORECORDER/PAUSE.
            
            try
                resume(obj.audiorecorderImpl);
            catch exception
                throwAsCaller(exception);
            end
        end
        
        function record(obj, varargin)
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
            %       r = audiorecorder(22050, 16, 1);
            %       record(r);     % speak into microphone...
            %       stop(r);
            %       p = play(r);   % listen to complete recording
            %
            %    See also AUDIORECORDER, AUDIORECORDER/PAUSE,
            %             AUDIORECORDER/STOP, AUDIORECORDER/RECORDBLOCKING.
            %             AUDIORECORDER/PLAY, AUDIORECORDER/RESUME.
            
            try
                record(obj.audiorecorderImpl, varargin{:});
            catch exception
                throwAsCaller(exception);
            end
        end
        
        function recordblocking(obj, varargin)
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
            %       r = audiorecorder(22050, 16, 1);
            %       recordblocking(r, 5);     % speak into microphone...
            %       p = play(r);   % listen to complete recording
            %
            %    See also AUDIORECORDER, AUDIORECORDER/PAUSE,
            %             AUDIORECORDER/STOP, AUDIORECORDER/RECORD.
            %             AUDIORECORDER/PLAY, AUDIORECORDER/RESUME.
            
            %      
            
            try
                recordblocking(obj.audiorecorderImpl, varargin{:});
            catch exception
                throwAsCaller(exception);
            end   
        end
        
        function data = getaudiodata(obj, varargin)
            %GETAUDIODATA Gets recorded audio data in audiorecorder object.
            %
            %    GETAUDIODATA(OBJ) returns the recorded audio data as a double array
            %
            %    GETAUDIODATA(OBJ, DATATYPE) returns the recorded audio data in
            %    the data type as requested in string DATATYPE.  Valid data types
            %    are 'double', 'single', 'int16', 'uint8', and 'int8'.
            %
            %    See also AUDIORECORDER, AUDIODEVINFO, AUDIORECORDER/RECORD.
            
            try
                data = getaudiodata(obj.audiorecorderImpl, varargin{:});
            catch exception
                throwAsCaller(exception);
            end
        end

        function player = play(obj, varargin)
            %PLAY Plays recorded audio samples in audiorecorder object.
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

            try
                player = play(obj.audiorecorderImpl,varargin{:});
            catch exception
                throwAsCaller(exception);
            end
        end
        
    end
end
