classdef (CaseInsensitiveProperties=true, TruncatedProperties=true) ...
        audioplayer < matlab.mixin.SetGet  & ...
                      matlab.mixin.CustomDisplay
    %audioplayer Audio player object.
    %   
    %   audioplayer(Y, Fs) creates an audioplayer object for signal Y, using
    %   sample rate Fs.  A handle to the object is returned.
    %
    %   audioplayer(Y, Fs, NBITS) creates an audioplayer object and uses NBITS
    %   bits per sample for floating point signal Y.  Valid values for NBITS
    %   are 8, 16, and 24.  The default number of bits per sample for floating
    %   point signals is 16.
    %
    %   audioplayer(Y, Fs, NBITS, ID) creates an audioplayer object using
    %   audio device identifier ID for output.  If ID equals -1 the default
    %   output device will be used.
    %
    %   audioplayer(R) creates an audioplayer object from AUDIORECORDER object R.
    %
    %   audioplayer(R, ID) creates an audioplayer object from AUDIORECORDER
    %   object R using audio device identifier ID for output.
    %
    % audioplayer Methods:
    %   get          - Query properties of audioplayer object.
    %   isplaying    - Query whether playback is in progress.
    %   pause        - Pause playback.
    %   play         - Play audio from beginning to end.
    %   playblocking - Play, and do not return control until playback
    %                  completes.
    %   resume       - Restart playback from paused position.
    %   set          - set properties of audioplayer object.
    %   stop         - stop playback.
    %
    % audioplayer Properties:
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
    %       p = audioplayer(y, Fs);
    %       play(p, [1 (get(p, 'SampleRate') * 3)]);
    %
    % See also AUDIORECORDER, AUDIODEVINFO, AUDIODEVRESET, 
    %          AUDIOPLAYER/GET, AUDIOPLAYER/SET.
    
    % Author(s): SM NH DTL
    % Copyright 1984-2023 The MathWorks, Inc.
    %   
    
    % --------------------------------------------------------------------
    % General properties
    % --------------------------------------------------------------------
    properties(Dependent, GetAccess='public', SetAccess='public')
        SampleRate              % Sampling frequency in Hz.
    end
    
    properties(Dependent, GetAccess='public', SetAccess='private')
        BitsPerSample           % Number of bits per audio Sample
        NumChannels             % Number of channels of the device
        DeviceID                % ID of the Device to be used for playback
    end
    
    properties(GetAccess='public', SetAccess='private', Hidden, Dependent)
        NumberOfChannels        % Number of channels of the device
    end
    
    % --------------------------------------------------------------------
    % Playback properties
    % --------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='private', Dependent)
        CurrentSample           % Current sample number being played
        TotalSamples            % Total number of samples being played
        Running                 % Is the player in running state
    end
    
    % --------------------------------------------------------------------
    % Callback Properties
    % --------------------------------------------------------------------
    properties(Dependent, GetAccess='public', SetAccess='public')
        StartFcn                % Handle to a user-specified callback function executed once when playback starts.
        StopFcn                 % Handle to a user-specified callback function executed once when playback stops.
        TimerFcn                % Handle to a user-specified callback function executed repeatedly (at TimerPeriod intervals) during playback.
        TimerPeriod             % Time, in seconds, between TimerFcn callbacks.
        Tag                     % User-specified object label string.
        UserData                % Some user defined data.
    end
    
    properties(Dependent, GetAccess='public', SetAccess='private')
        Type                    % For backward compatibility
    end
    
    properties(Access='private')
        audioplayerImpl
    end

    % --------------------------------------------------------------------
    % Lifetime
    % --------------------------------------------------------------------
    methods(Hidden, Access='public')        
        function obj = audioplayer(varargin)
            narginchk(1,4);
            import matlab.internal.capability.Capability;
            % Create a audioplayerDesktop object or audioplayerOnline
            % object based on where this is running.
            try
                if Capability.isSupported(Capability.LocalClient)
                    obj.audioplayerImpl = audiovideo.internal.audioplayerDesktop(varargin{:});
                else
                    % This is running in MATLAB Online, create a
                    % audioplayerOnline object.
                    obj.audioplayerImpl = audiovideo.internal.audioplayerOnline(varargin{:});
                end
            catch exception
                % If there were errors creating a audioplayerOnline or
                % audioplayerDesktop object, error out.
                throw(exception);
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
                s = getString(message( 'MATLAB:audiovideo:audioplayer:BitsPerSampleIgnored'));
            end
        end
    end
    
    methods      
        function value = get.BitsPerSample(obj)
            value = obj.audioplayerImpl.BitsPerSample;
        end
        
        function value = get.CurrentSample(obj)
            value = obj.audioplayerImpl.CurrentSample;
        end
        
        function value = get.DeviceID(obj)
            value = obj.audioplayerImpl.DeviceID;
        end
        
        function value = get.NumChannels(obj)
            value = obj.audioplayerImpl.NumChannels;
        end
        
        function value = get.NumberOfChannels(obj)
            value = obj.audioplayerImpl.NumChannels;
        end        
        
        function value = get.Running(obj)
            value = obj.audioplayerImpl.Running;
        end        
        
        function value = get.SampleRate(obj)
            value = obj.audioplayerImpl.SampleRate;
        end
        
        function set.SampleRate(obj, val)
            obj.audioplayerImpl.SampleRate = val;
        end          
        
        function value = get.TotalSamples(obj)
            value = obj.audioplayerImpl.TotalSamples;
        end
        
        function value = get.Tag(obj)
            value = obj.audioplayerImpl.Tag;
        end

        function set.Tag(obj, val)
            obj.audioplayerImpl.Tag = val;
        end  
        
        function value = get.Type(obj)
            value = obj.audioplayerImpl.Type;
        end
        
        function value = get.UserData(obj)
            value = obj.audioplayerImpl.UserData;
        end        
        
        function set.UserData(obj, val)
            obj.audioplayerImpl.UserData = val;
        end         
        
        function value = get.StartFcn(obj)
            value = obj.audioplayerImpl.StartFcn;
        end   
        
        function set.StartFcn(obj, val)
            obj.audioplayerImpl.StartFcn = val;
        end 
        
        function value = get.StopFcn(obj)
            value = obj.audioplayerImpl.StopFcn;
        end
        
        function set.StopFcn(obj, val)
            obj.audioplayerImpl.StopFcn = val;
        end         
        
        function value = get.TimerFcn(obj)
            value = obj.audioplayerImpl.TimerFcn;
        end      
        
        function set.TimerFcn(obj, val)
            obj.audioplayerImpl.TimerFcn = val;
        end         
        
        function value = get.TimerPeriod(obj)
            value = obj.audioplayerImpl.TimerPeriod;
        end         
        
        function set.TimerPeriod(obj, val)
            obj.audioplayerImpl.TimerPeriod = val;
        end         
    end
    
    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence.
        %------------------------------------------------------------------
        function obj = loadobj(B)
            if isprop(B, 'audioplayerImpl')
                obj = B;
                return;
            end
            
            if isfield(B, 'internalObj')
                savedObj = struct(B);
                props = savedObj.internalObj;
                signal = savedObj.signal;
                
                obj = audioplayer(signal, props.SampleRate, props.BitsPerSample, ...
                    props.DeviceID);
                
            else
                obj = audioplayer(B.AudioData, B.SampleRate, B.BitsPerSample, ...
                    B.DeviceID);
                props = B;
            end            
            
            % Set the original settable property values.
            %propNames = fieldnames(set(obj));
            propNames = getSettableProperties(obj.audioplayerImpl);
            
            for i = 1:length(propNames)
                try
                    set(obj.audioplayerImpl, propNames{i}, props.(propNames{i}));
                catch %#ok<CTCH>
                    warning(message('MATLAB:audiovideo:audioplayer:couldnotset', propNames{ i }));
                end
            end
        end
    end
    
    methods(Access='public', Hidden)
        function clearAudioData(obj)
            try
                clearAudioData(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
            end
        end
    end
      
    %----------------------------------------------------------------------
    % audioplayer Functions
    %----------------------------------------------------------------------
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
            
            try
                play(obj.audioplayerImpl, varargin{:});
            catch exception
                throwAsCaller(exception);
            end            
        end
        
        function status = isplaying(obj)
            %ISPLAYING Indicates if playback is in progress.
            %
            %    STATUS = ISPLAYING(OBJ) returns true or false, indicating
            %    whether playback is or is not in progress.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET.
            
            try
                status = isplaying(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
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
            try
                stop(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
            end
        end
        
        function delete(obj)
            %DELETE the object and performs cleanup.
            try
                delete(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
            end
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
            try
                pause(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
            end         
         end
        
        function resume(obj)
            %RESUME Resumes paused playback.
            %
            %    RESUME(OBJ) continues playback from paused location.
            %
            %    See also AUDIOPLAYER, AUDIODEVINFO, AUDIOPLAYER/GET,
            %             AUDIOPLAYER/SET, AUDIOPLAYER/PAUSE.
            try
                resume(obj.audioplayerImpl);
            catch exception
                throwAsCaller(exception);
            end          
        end
        
        
        function playblocking(obj, varargin)
            %PLAYBLOCKING Synchronous playback of audio samples in audioplayer object.
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
            
            try
                playblocking(obj.audioplayerImpl, varargin{:});
            catch exception
                throwAsCaller(exception);
            end
        end       
        
    end
end
