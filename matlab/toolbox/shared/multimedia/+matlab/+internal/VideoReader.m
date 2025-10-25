classdef VideoReader < matlab.mixin.SetGet & matlab.mixin.CustomDisplay
%#codegen
%   matlab.internal.VideoReader Create an internal video reader object.
%
%   obj = matlab.internal.VideoReader(FILENAME) constructs an object that 
%   can read in video data from a multimedia file.  FILENAME is a string
%   specifying the name of a multimedia file. By default, MATLAB looks for 
%   the file FILENAME on the MATLAB path.
%
%   Methods:
%     readNextFrame       - Read the next available frame from a video file
%     hasFrame            - Determine if there is a frame available to read
%                           from a video file. 
%     readFrameAtPosition - Read the frame at a given time or a given
%                           index. For time based seeking, the input to
%                           this function should be a duration. For frame
%                           based seeking, the input should be a integer
%                           valued numeric (including doubles)
%
%   Properties:
%     Name              - Name of the file to be read.
%     Path              - Path of the file to be read.
%     Width             - Width of the video frame in pixels.
%     Height            - Height of the video frame in pixels.
%     BitsPerPixel      - Bits per pixel of the video data.
%     FrameRate         - Frame rate of the video in frames per second.
%     VideoFormat       - Video format as it is represented in MATLAB.
%     Duration          - Length of the file in seconds
%     LastTimestampRead - Timestamp of the last frame read
%     Timestamps        - The timestamp vector of the video
%     NumFrames         - Number of frames in the video
%
%   Example:
%       % Construct a multimedia reader object associated with file
%       % xylophone.mp4
%
%       vidObj = matlab.internal.VideoReader('xylophone.mp4');
%
%       % Get the timestamp vector for this video
%       ts = vidObj.Timestamps;
%
%       % Read the first frame of the video
%       vidFrame = readNextFrame(vidObj)
%       
%       % Display the frame
%       imshow(vidFrame.Data)
%      
%       % Read the frame at 3.3 seconds
%       time = seconds(3.3);
%       vidFrame = readFrameAtPosition(vidObj, time);
%
%       % Read the 10th frame
%       vidFrame = readFrameAtPosition(vidObj, 10);

%   Copyright 2016-2024 The MathWorks, Inc.

    properties(GetAccess='public', SetAccess='private')
        
        % General properties
        Name;               % Name of the file to be read
        Path;               % Path of the file to be read
        
        % VideoReader properties
        LastTimestampRead;
    end
    
    properties(GetAccess='public', SetAccess='private', Dependent)
        
        % Video properties
        Width;                % Width of the video frame in pixels
        Height;               % Height of the video frame in pixels
        BitsPerPixel          % Bits Per Pixel of the video data
        FrameRate;            % Frame rate of the video in frames per second
        Duration;             % Length of the file in seconds
        VideoFormat;          % Format of the video stream
        Timestamps;           % Timestamp vector for the file
        NumFrames;            % Number of frames in the video 
    end
    
    properties(GetAccess='public', SetAccess='private', Dependent, Hidden)
        
        % Video properties
        Colormap;             % Color Map in the video
        HasVideo              % Media has video
        HasAudio              % Media has audio
        AudioCompression
        NumAudioChannels
        NumColorChannels
        VideoCompression
        IsNumFramesAvailable  % Flag to indicte if the timestamp computation 
                              % has been completed which indicates the 
                              % NumFrames property is available
    end  
    
    
    properties(Access='private', Dependent, Transient)
        InitOptions;
    end
    
    properties(Access='private')
        % Last index read: to optimize performance and prevent re-seeking.
        % This is only for reading using indices and not for stream based reading 
        % LastFrameIndexRead = -1 denotes stream based reading
        LastFrameIndexRead = 0;
    end
    
    properties(SetAccess='private', Hidden)
        ReadInterval = 1;       % Number of frames to skip after every read
    end
    
    properties(Access='private', Hidden, Transient)
        Channel;
        TimestampChannel;
        NumTimestampsRead;
        TimestampsCompleteAndSorted;
        InternalTimestamps;
        CachedFrame = [];
    end
    
    properties(Constant, Access='private')
        NumFramesToBuffer = 10;
        
        NumTimestampsToBuffer = Inf;
       
        % For frame based reading, since the timestamps may not come in a
        % sorted order, we will read these many extra frames so that we can
        % ensure that the requested frame index is available
        NumExtraTimestampsToReadForFrameBased = 50;
        
        ErrorPrefix = 'VideoReader';

        % Number of PropertyGroup for VideoReader object properties
        NumPropertyGroups = 3;
    end
    
    properties(Access='private', Hidden)
        % To help support future forward compatibility.
        SchemaVersion = 1.0;
    end
    
    events(NotifyAccess='public')
        TimestampsUpdated;
        TimestampsComplete;
    end
   
    methods(Access='public')
        %------------------------------------------------------------------
        % Lifetime
        %------------------------------------------------------------------
        function obj = VideoReader(filename, varargin)            
            p = inputParser;
            addRequired(p, 'filename', @(x) validateattributes( x, {'char','string'}, ...
                                                                {'scalartext', 'nonempty'}));
            addParameter(p, 'ComputeTimestampsOnCreation', true, ...
                         @(x) validateattributes( x, {'logical'}, {'scalar'} ));   
            parse(p, filename, varargin{:});
            computeTimestampsOnCreation = p.Results.ComputeTimestampsOnCreation;

            if ~matlab.io.internal.vfs.validators.hasIriPrefix(filename)
                % if the file is local, get fullname with absolutePathForReading
                try
                    fullname = multimedia.internal.io.absolutePathForReading(...
                                filename, ...
                                'multimedia:videofile:FileNotFound', ...
                                'multimedia:videofile:FilePermissionDenied');
                catch ME
                    % This is done to ensure that we add the suitable prefix to
                    % the error ID.
                     matlab.internal.VideoReader.throwError( ...
                                                    message(ME.identifier) );
                end
            else
                % Check if the remote file is found
                if(~isfile(filename))
                    % Check if the cloud environment variables are set
                    matlab.io.internal.vfs.validators.validateCloudEnvVariables(filename);
                    ME = MException('multimedia:videofile:resourceNotFound', message('multimedia:videofile:resourceNotFound', ...
                            filename).getString);
                    throwAsCaller(ME);
                end

                % Check if user has read permission
                if ~matlab.io.internal.filesystem.getPerms(filename, "File", ["Readable", "Writable"]).Readable
                    ME = MException('multimedia:videofile:FilePermissionDenied', ...
                        message('multimedia:videofile:FilePermissionDenied').getString);
                    throwAsCaller(ME);
                end

                % if the file is cloud hosted, use the filename as the fullname.
                fullname = filename;
            end
                        
            [pathstr, name, ext] = fileparts(fullname);
            obj.Name = [name, ext];
            obj.Path = pathstr;
            
            % Throw error if this is an image or text file
            % skip this check for cloud hosted files because these two functions only works for local file.
            % running this function for cloud file will need downloading the entire file to local, which take a long time.
            isRemote = matlab.io.internal.vfs.validators.hasIriPrefix(filename);
            if ~isRemote
                obj.errorIfImageFormat(fullname);
            end
            obj.errorIfTextFormat(fullname);

            % Throw an error if this is a .MAT file
            if ~isempty(ext) && strcmp(ext,'.mat')
                matlab.internal.VideoReader.throwError( ...
                            message('multimedia:videofile:FileTypeNotSupported') );
            end

            % Initialze time stamp related data members
            obj.InternalTimestamps = [];
            obj.TimestampsCompleteAndSorted = false;
            
            try
                createChannel(obj, obj.InitOptions, computeTimestampsOnCreation);
                if obj.HasVideo
                    openChannel(obj);                
                end
                obj.LastTimestampRead = seconds(NaN);
            catch ME
                if isRemote && ...
                        any(matlab.io.internal.vfs.validators.GetScheme(fullname) == ["http", "https"]) && ...
                        contains(matlab.io.internal.filesystem.getContentType(fullname), "text/html", IgnoreCase=true)
                    % If the file being read is from an HTTP link and its content type is HTML,
                    % throw an error. This is because we are attempting to read the HTML content
                    % as one of the supported formats. This scenario can occur when the HTTP link
                    % requires authentication, and instead of the desired content, we receive a
                    % login page.
                    error(message('multimedia:videofile:readHTML', fullname));
                else
                    throwAsCaller(ME);
                end
            end

            % Read ahead one frame
            cacheNextFrame(obj);
        end
        
        
        function delete(obj)
            if ~isempty(obj.TimestampChannel)
                if obj.TimestampChannel.isOpen()
                    obj.TimestampChannel.close();
                end
                obj.TimestampChannel.InputStream.flush();
            end
            
            if ~isempty(obj.Channel)
                closeChannel(obj);
                obj.Channel.InputStream.flush();
            end
        end
        
        %------------------------------------------------------------------
        % Public methods for reading frames
        %------------------------------------------------------------------
        
        % readFrameAtPosition
        % Reads frame at:
        % i) The time specified by position if it is a duration
        % ii) The frame number specified by position if it is an integer
        % valued numeric. This will wait for the timestamps vector to have
        % at least as many elements as the frame number requested. For
        % example, a call to readFrameAtPosition(obj, 50) will return the
        % 50th element in the timestamp vector. Currently, frame based
        % seeking will not work reliably for videos that return frames in
        % an unsorted order
        % third argument shows whether the stream needs to be opened in
        % Native or Default read mode
        function vidFrame = readFrameAtPosition(obj, position)
            if ~obj.HasVideo
                vidFrame = [];
                return;
            end
            
            if isduration(position)
                validateattributes(seconds(position), {'numeric'}, ...
                                        {'scalar', 'nonnan', 'nonnegative', 'finite'});
            else
                validateattributes(position, {'numeric'}, ...
                                                    {'scalar', 'nonnan', 'positive', 'integer'});
            end
                                                
            if isa(position, 'numeric')
                vidFrame  = readFrameAtIndex(obj, position);
                obj.LastFrameIndexRead = position;
            else
                obj.LastFrameIndexRead = -1;
                vidFrame = readFrameAtTime(obj, position);
            end
        end

        %------------------------------------------------------------------
        % readNextFrame: Reads the next available frame from the video
        %------------------------------------------------------------------
        function vidFrame = readNextFrame(obj)
            if ~obj.HasVideo
                vidFrame = [];
                return;
            end
            
            % If there are no more frames available to read from the file,
            % throw the suitable error.
            if ~hasFrame(obj)
                obj.LastFrameIndexRead = -1;
                matlab.internal.VideoReader.throwError( ...
                            message('multimedia:videofile:EndOfFile') );
            end
            
            % An empty cached-frame indicates there are no more frames
            % available to read from the file. If the code reaches here, it
            % indicates either a valid or invalid read occurred.
            if isinf(obj.CachedFrame.Timestamp)
                obj.LastFrameIndexRead = -1;
                matlab.internal.VideoReader.throwError( ...
                            message('multimedia:videofile:ReadFailed') );
            end
                
            % The CachedFrame has to be valid at this point.                
            vidFrame = obj.CachedFrame;
            
            % The frame-data returned from the underlying frame-work is in
            % row-major interleaved layout. Transform this column-major
            % planar layout
            % vidFrame.Data = permute(vidFrame.Data, [3 2 1]);            
            vidFrame.Timestamp = seconds(vidFrame.Timestamp);
            
            % Update the LastTimestampRead property
            obj.LastTimestampRead = vidFrame.Timestamp;
            
            % Update the LastFrameIndexRead property  
            % obj.LastFrameIndexRead = -1 denotes stream based reading
            if(obj.LastFrameIndexRead ~= -1)
                obj.LastFrameIndexRead = obj.LastFrameIndexRead + 1;
            end
            
            % Read ahead
            cacheNextFrame(obj);
        end
        
        
        %------------------------------------------------------------------
        % hasFrame: returns true if there are more frames available to read
        %------------------------------------------------------------------
        function out = hasFrame(obj)
            out = ~isempty(obj.CachedFrame);
        end      
    end
    
    % Save/load methods
    methods( Access='public' )
        function infoToSave = saveobj(obj)
            infoToSave.SchemaVersion = obj.SchemaVersion;
            
            % It is sufficient to save the filename as the properties of
            % the video being read can be obtained from the file.
            infoToSave.FileName = fullfile(obj.Path, obj.Name);
            
            % These properties are necessary to restore the object to the
            % exact state it was saved in.
            infoToSave.ReadInterval = obj.ReadInterval;
            infoToSave.LastTimestampRead = obj.LastTimestampRead;
        end
    end
    
    methods(Static)
        function obj = loadobj(savedInfo)
            obj = matlab.internal.VideoReader(savedInfo.FileName);
            obj.ReadInterval = savedInfo.ReadInterval;
            
            % Seek to the appropriate position in the video stream
            if ~isnan(savedInfo.LastTimestampRead)
                readFrameAtPosition(obj, savedInfo.LastTimestampRead);
            end
        end
        
        % Instruct MATLAB Coder to use a different implementation for this
        % class when generating C/C++ Code.
        function name = matlabCodegenRedirect(~)
            name = 'matlab.internal.coder.VideoReader';
        end
    end
    
    % Getters
    methods            
        function width = get.Width(obj)
            width = obj.Channel.Width;
        end
        
        function height = get.Height(obj)
            height = obj.Channel.Height;
        end
        
        function fr = get.FrameRate(obj)
            fr = obj.Channel.FrameRate;
        end
        
        function duration = get.Duration(obj)
            duration = seconds(obj.Channel.Duration);
        end
        
        function bpp = get.BitsPerPixel(obj)
            bpp = obj.Channel.BitsPerPixel;
        end
        
        function vf = get.VideoFormat(obj)
            vf = obj.Channel.VideoFormat;
        end
        
        function tsVector = get.Timestamps(obj)
        % returns the timestamp vector of the video, which
        % is a column vector of duration objects. This is a blocking call,
        % it will wait for all timestamps to be populated
        
            % Open the timestamp channel if it is closed.
            if ~isempty(obj.TimestampChannel)
                if ~obj.TimestampChannel.isOpen()
                    openTimestampChannel(obj);
                end
            end
            
            while ~obj.TimestampsCompleteAndSorted
                
                % All DataWritten events to be processed so that timestamp
                % vector can be updated.
                drawnow limitrate
                if ~hasTimestamps(obj)
                    sortTimestampsAndBroadcastEvent(obj);
                    break;
                end
            end
            tsVector = obj.InternalTimestamps;
        end
        
        function numFrames = get.NumFrames(obj)
            % returns the number of frames in the video
            numFrames = -1;
            if isprop(obj.Channel, 'NumFrames')
                % The asyncio Channel object contains a NumFrames property
                % for DirectShow plugin as this plugin returns the number
                % of frames instantaneously for some formats. In this case,
                % we can just query this property and do not need to wait
                % for the timstamps to be populated
                numFrames = obj.Channel.NumFrames;
            end
            
            if numFrames == -1
                % If the timestamp Channel has not yet been opened, open it
                openTimestampChannel(obj);
                numFrames = numel(obj.Timestamps);          
            end
        end
        
        function colorMap = get.Colormap(obj)
            % returns Colormap
            if hasCustomProp(obj.Channel, 'Colormap')
                % The asyncio Channel object contains a Colormap property
                % for Grayscale and Indexed images
                colorMap = obj.Channel.Colormap;
                numEntries = length(colorMap) / 3;
                colorMap = double( reshape(colorMap, 3, numEntries)' );
            else
                colorMap = NaN;
            end
        end   

        function tf = get.HasVideo(obj)
            tf = obj.Channel.HasVideo;
        end
        
        function tf = get.HasAudio(obj)
            tf = obj.Channel.HasAudio;
        end   
        
        function numAudioChannels = get.NumAudioChannels(obj)
            numAudioChannels = obj.Channel.NumAudioChannels;
        end
        
        function numColorChannels = get.NumColorChannels(obj)
            numColorChannels = obj.Channel.NumColorChannels;
        end        
        
        function vc = get.VideoCompression(obj)
            vc = obj.Channel.VideoCodec;
        end
        
        function ac = get.AudioCompression(obj)
            ac = obj.Channel.AudioCodec;
        end
        
        function tf = get.IsNumFramesAvailable(obj)
            tf = obj.TimestampsCompleteAndSorted;
        end
    end
       
    %----------------------------------------------------------------------
    % Display methods
    % These methods are used only when displaying the properties of the
    % VideoReader object, for example, 
    % >> matlab.internal.VideoReader('xylophone.mp4')
    %----------------------------------------------------------------------
    methods (Access='protected')
        function propGroups = getPropertyGroups(obj)
           import matlab.mixin.util.PropertyGroup;
           % Initialize propGroups with empty PropertyGroup object
           propGroups = [PropertyGroup.empty(0, obj.NumPropertyGroups)];
           propGroups(1) = PropertyGroup( {'Name', 'Path'},...
                                          getString( message('multimedia:videofile:GeneralProperties') ) );
                                      
           propGroups(2) = PropertyGroup( {'Width', 'Height', 'FrameRate',...
                                           'VideoFormat', 'Duration'},...
                                           getString( message('multimedia:videofile:VideoProperties') ) );
                                       
           propGroups(3) = PropertyGroup( {'LastTimestampRead'}, ...
                                          getString( message('multimedia:videofile:ReadProperties') ) );                           
        end
        
        function header = getHeader(obj)
            headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            header = sprintf('matlab.internal.%s with properties:\n', headerStr);
        end
    end
    
    %----------------------------------------------------------------------
        % Helpers
    %----------------------------------------------------------------------
    
    methods (Access='private')
        %------------------------------------------------------------------
        % Async I/O Channel helpers
        %------------------------------------------------------------------
        function createChannel(obj, deviceInitOptions, computeTimestampsOnCreation)
            
            import matlab.internal.video.PluginManager;
            try
                [devicePlugin, tsPlugin, tsInitOptions] = ...
                    PluginManager.getInstance.getPluginForRead(deviceInitOptions.Filename);
            catch ME
                % Indicates that no plugins are able to read this file.
                % This could be either because the file is unsupported or
                % corrupt.
                ME = PluginManager.replacePluginExceptionPrefix(ME, ...
                                        'multimedia:VideoReader');
                throwAsCaller(ME);
            end
            
            % Create the Device Plugin
            try
                obj.Channel = matlabshared.asyncio.internal.Channel( devicePlugin, ...
                                               PluginManager.getInstance.MLConverter, ...
                                               Options = deviceInitOptions, ...
                                               StreamLimits = [obj.NumFramesToBuffer, 0] );
            catch ME
                % Indicates that no plugins are able to read this file.
                % This could be either because the file is unsupported or
                % corrupt.
                ME = PluginManager.replacePluginExceptionPrefix(ME, ...
                                        'multimedia:VideoReader');
                throwAsCaller(ME);
            end
           
            % At this point, the device plugin has been successfully
            % created.        
            % Create the Timestamp channel if necessary
            if isempty(tsPlugin)
                % Indicates that Motion JPEG AVI or MJ2000 file plugin is
                % being used
                obj.TimestampChannel = [];
                obj.InternalTimestamps = seconds( 0:1/obj.Channel.FrameRate:...
                                                  obj.Channel.Duration + ...
                                                  eps(obj.Channel.Duration) )';
                obj.InternalTimestamps(end) = [];
                notify(obj, 'TimestampsComplete');
                obj.TimestampsCompleteAndSorted = true;
                return
            end
            
            % Indicates that timestamp information needs to be
            % obtained from the video file.
            % Create the Timestamp channel and start reading timestamps
            try
                tsInitOptions.Filename = deviceInitOptions.Filename;
                obj.TimestampChannel = matlabshared.asyncio.internal.Channel( tsPlugin,...
                                                        PluginManager.getInstance.MLConverter, ...
                                                        Options = tsInitOptions, ...
                                                        StreamLimits = [matlab.internal.VideoReader.NumTimestampsToBuffer, 0] );
                
                % Create a weak reference to the object to prevent increasing its reference count.
                % This allows the object to be garbage collected if there are no other strong references.
                objWeakRef = matlab.lang.WeakReference(obj);
                % Create a listener to update timestamps
                obj.TimestampChannel.InputStream.addlistener('DataWritten', ...
                    @(varargin)objWeakRef.Handle.updateTimestamps(varargin{:}));


                % If the Timestamps need to be computed at the creation of
                % the object, open the Timestamp channel
                if computeTimestampsOnCreation
                    openTimestampChannel(obj);
                end
            catch ME
                ME = PluginManager.replacePluginExceptionPrefix(ME, ...
                                        'multimedia:VideoReader');
                throwAsCaller(ME);
            end
        end
        
        % Throw error if asyncio channel does not exist
        function validateChannelExists(obj)
            if isempty(obj.Channel)
                assert(false, 'Channel for reading video does not exist');
            end
        end
               
        % Open the channel if it is closed
        function openChannel(obj, startPosition)
            validateChannelExists(obj);
            
            if obj.Channel.isOpen()
                return;
            end
            
            try
                % Configure the device plugins to return row-major
                % interleaved data to improve performance
                openOptions.IsOutputRowMajorInterleaved = true;
                if nargin == 2
                    openOptions.ReadPosition = startPosition;
                end
                obj.Channel.open(openOptions);
            catch ME
                throwAsCaller(ME);
            end
        end

        % Open the Timestamp channel if it is closed
        function openTimestampChannel(obj)
            if isempty(obj.TimestampChannel)
                return;
            end
            if ~obj.TimestampChannel.isOpen()
                try
                    obj.TimestampChannel.open();                  
                catch ME
                    throwAsCaller(ME);
                end
            end
        end
        
        % Close the channel if it is open
        function closeChannel(obj)
            validateChannelExists(obj);
            if obj.Channel.isOpen()
                try
                    obj.Channel.close();
                catch ME
                    throwAsCaller(ME);
                end
            end
        end        
        
        %------------------------------------------------------------------
        % Timestamp helpers
        %------------------------------------------------------------------
        function updateTimestamps(obj, ~, ~)
            
            % Read all the available timestamps
            [data, ~] = obj.TimestampChannel.InputStream.read();  
            
            % Append the timestamps to obj.InternalTimestamps
            obj.InternalTimestamps = [obj.InternalTimestamps; seconds(data)];
            
            % Broadcast a TimestampsUpdated event
            notify(obj, 'TimestampsUpdated');
            
            % Broadcast a TimestampsComplete event if done reading
            % timestamps
            if ~hasTimestamps(obj)
                sortTimestampsAndBroadcastEvent(obj);
            end
        end
        
        
        function out = hasTimestamps(obj)
            if ~isempty(obj.TimestampChannel)
                endOfFile = obj.TimestampChannel.InputStream.isDeviceDone() && ...
                            (obj.TimestampChannel.InputStream.DataAvailable == 0);
                out = ~endOfFile;
            else
                out = false;
            end
        end
        
        % Helper function for sorting timestamps and broadcasting
        % TimestampsComplete event
        function sortTimestampsAndBroadcastEvent(obj)
            % If all elements of the diff of timestamps are non negative
            % it means that the timestamps are already sorted. If not, then
            % we need to sort them.
            if ~(all(diff(obj.InternalTimestamps)>=0))
                obj.InternalTimestamps = sort(obj.InternalTimestamps);
            end
            if isinf(obj.InternalTimestamps(end))
                obj.InternalTimestamps = obj.InternalTimestamps(1:end-1);
            end
            
            obj.TimestampsCompleteAndSorted = true;
            notify(obj, 'TimestampsComplete');
        end
        
        %------------------------------------------------------------------
        % readFrameAtPosition helpers
        %------------------------------------------------------------------
        function vidFrame = readFrameAtTime(obj, inputTime)
           % negative values of time are permitted because of certain files
           % which have negative timestamps.
           
            % Timestamp specified can be anywhere in the file and so the
            % cached frame, ReadAheadPluginException and
            % AsyncFrameReaderException are no longer valid.
            obj.CachedFrame = [];
                    
            % Close channel so it can be re-opened with
            % updated options
            closeChannel(obj);
            
            % Flush the input stream for any data remaining from the 
            % last read
            % TODO: Make this method smarter so that if the
            % requested timestamp is already in the buffer, we do not
            % need to flush all the frames
            obj.Channel.InputStream.flush();
   
            openChannel(obj, seconds(inputTime));
            
            cacheNextFrame(obj);
                        
            vidFrame = readNextFrame(obj);
        end
        
        function vidFrame = readFrameAtIndex(obj, index)
            % Returns the video frame that is the (index)th frame in the
            % video. index should be a positive integer
            
            if index == obj.LastFrameIndexRead+1
                vidFrame = readNextFrame(obj);
                return;
            end
            
            % If the position specified is not the immediate next one, then
            % the frame that has been cached is no longer valid.
            obj.CachedFrame = [];
            
            % If the timestamp Channel has not yet been opened, open it
            openTimestampChannel(obj);
            
           % Wait for the number of elements in the internal timestamp
           % vector to be a little more than the index of frames requested.
           % This is because for some video formats, the timestamp vector
           % might not be sorted so we need to read some extra timestamps
           % to ensure that the requested timestamp has been received
           while numel(obj.InternalTimestamps) < index + obj.NumExtraTimestampsToReadForFrameBased ...
                 && ...
                 hasTimestamps(obj)
             
               % The desired timestamp hasn't been loaded yet
               drawnow limitrate
           end
           
           if numel(obj.InternalTimestamps) < index
               matlab.internal.VideoReader.throwError( ...
                        message('multimedia:videofile:invalidFrameIndex') );
           end
           % Timestamp vector containing all the timestamps loaded till now
           partialTimestampVector = obj.InternalTimestamps;
           
           % Sort this vector if it is unsorted
           if ~issorted(partialTimestampVector)
               partialTimestampVector = sort(partialTimestampVector);
           end
           vidFrame = obj.readFrameAtTime(partialTimestampVector(index));
        end
        
        function cacheNextFrame(obj)
            % If an empty frame is read, it means end-of-file has been
            % read.
            % If the timestamp of the frame read is Inf, it indicates an
            % error occurred when reading the frame.
            % If neither of the above situations occur, it indicates a
            % valid frame has been read.
            obj.CachedFrame = obj.Channel.InputStream.read(1);
        end
    end
    
    methods
        function initOptions = get.InitOptions(obj)
            initOptions.Filename = strcat(obj.Path, '/', obj.Name);
            
            initOptions.UseHardwareAcceleration = matlab.internal.video.isHardwareAccelerationUsed();
        end
    end
    
    
    methods (Static, Access='private', Hidden)
        function errorIfImageFormat( fileName )
            isImageFormat = false;
            try 
                % see if imfinfo recognizes this file as an image
                imfinfo( fileName );
               
                isImageFormat = true;
                
            catch exception %#ok<NASGU>
                % imfinfo does not recognize this file, don't error
                % since it is most likely a valid multimedia file
            end
            
            if isImageFormat
                % If imfinfo does not error, then show this error
                matlab.internal.VideoReader.throwError( ...
                        message('multimedia:videofile:unsupportedImage') );
            end
        end
        
        function errorIfTextFormat(fileName)
            %Don't try to open text files with known text extensions.
            [~,~,ext] = fileparts(fileName);
            textExts = {'txt','text','csv','html','xml','m'};
            if ~isempty(ext) && any(strcmpi(ext(2:end),textExts))
                matlab.internal.VideoReader.throwError( ...
                        message('multimedia:videofile:unsupportedText') );
            end
        end
        
        function throwError(msgObj)
            if ~isa(msgObj, 'message')
                assert( false, 'Input argument is not a message object' );
            end
            
            errorID = regexprep( msgObj.Identifier, 'videofile', ...
                                 matlab.internal.VideoReader.ErrorPrefix );
            throwAsCaller(MException(errorID, msgObj.getString()));
        end
        
    end
end
