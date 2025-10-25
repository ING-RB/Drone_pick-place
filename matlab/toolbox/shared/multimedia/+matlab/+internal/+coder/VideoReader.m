%#codegen

classdef VideoReader < handle
%   matlab.internal.coder.VideoReader Implementation for the
%   code-generation version of matlab.internal.VideoReader 
%   MATLAB Coder redirects to this implementation when generating code.

%   Copyright 2016-2024 The MathWorks, Inc.
   properties(GetAccess='public', SetAccess='private')
        
        % General properties
        Name;               % Name of the file to be read
        Path;               % Path of the file to be read
        
        % VideoReader properties
        LastTimestampRead;
    end
    
    properties(GetAccess='public', SetAccess='private', Hidden, Dependent)
        % Video properties
        Colormap;             % Color Map if present in the video
        HasVideo              % TRUE if media file has video
        HasAudio              % TRUE if media file has audio
        AudioCompression
        NumAudioChannels
        NumColorChannels
        VideoCompression
        IsNumFramesAvailable  % Flag to indicte if the timestamp computation 
                              % has been completed which indicates the 
                              % NumFrames property is available
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
    
    properties(Access='private', Constant)
        NumFramesToBuffer = 10;
    end
    
    
    properties(Access='private', Transient)
        % Instance of the matlabshared.asyncios.internal.Channel that will be used to stream data
        Channel;
        
        % Stores the next frame present in the video file by reading ahead.
        % This is necessary to ensure that EOF is flagged correctly by this
        % object.
        CachedFrame;
        
        % A representative frame that is required by AsyncIO to determine
        % how to read data from the InputStream
        SampleFrame;
        
        % A frame that represents an empty frame. In MATLAB, a valid frame
        % is a STRUCT but an empty frame is denoted by []. However, these
        % are different types and a variable's type cannot be changed in
        % generated code. Hence, this empty frame is a STRUCT with a NaN
        % for the Timestamp.
        EmptyFrame;
        
        % Last index read: to optimize performance and prevent re-seeking.
        % This is only for reading using indices and not for stream based
        % reading  
        % LastFrameIndexRead = -1 denotes stream based reading
        LastFrameIndexRead = 0;
        
        % Currently, MATLAB Coder only supports reading uint8 data. This
        % flag tracks whether the video stream present in the file can be
        % decoded to a uint8 type.
        IsUint8Video = true;
        
        % Instance of the TimeStampManager class that is used to manage
        % timestamps for the frames in the video. This is required for
        % random access.
        TsHandler;
        
        % Flag to determine whether the input file name is a compile time
        % constant.
        IsFileConst = false;
        
        % Video properties of the file that was determined to be a compile
        % time constant. This property contains valid values only if the
        % file is a compile time constant. The properties contained are
        % only those needed to accurately describe a video frame.
        VidPropsConstFile;
    end
    
    properties(Access='private', Dependent)
        % Flag that determines if the matlabshared.asyncio.internal.Channel object created was
        % successfully able to read the file.
        IsPluginSuccess;
    end
    
    
    methods(Access='public')
       function obj = VideoReader(fileName, name, val)
           narginchk(1, 3);
           
           fileName = convertStringsToChars(fileName);
           
           % Validate that file name is a non-empty character row vector
           validateattributes(fileName, {'char', 'string'}, {'scalartext', 'nonempty'});
           
           % Validate name-value pairs when they are provided. Currently,
           % the only name-value pair supported is to determine if the
           % time-stamp channel will be created upon construction.
           if nargin > 1
               if nargin ~= 3
                   coder.internal.error('multimedia:videofile:coderInvalidNumArgs');
                   return;
               end
               validatestring(name, {'ComputeTimestampsOnCreation'}, 'VideoReader');
               validateattributes(val, {'logical'}, {'scalar'});
               isComputeTSOnObjCreation = val;
           else
               % Indicates that the timestamp handler will be created upon
               % object construction. 
               isComputeTSOnObjCreation = true;
           end
           
           % Determine if the file name specified was a constant at compile
           % time. This is useful for the following scenarios:
           % 1. Dimensions of the output frame can be determined at compile
           % time, thereby avoiding dynamic allocation in generated code.
           % 2. Support for Signed 8-bit and Signed/unsigned 16-bit videos
           % as the datatype can be resolved at compile time.
           
           coder.extrinsic('matlab.internal.coder.getVideoInfo');
           isFileConst = coder.const(coder.internal.isConst(fileName));
           if isFileConst
               vidPropsConstFile = coder.const(matlab.internal.coder.getVideoInfo(fileName));
           else
               % The values returned will be invalid but they will not be
               % used.
               vidPropsConstFile = coder.const(matlab.internal.coder.getVideoInfo());
           end
           
           obj.IsFileConst = isFileConst;
           obj.VidPropsConstFile = vidPropsConstFile;
           
           createChannel(obj, fileName, isComputeTSOnObjCreation);
           
           % Determine if the video stream present in the file decodes to a
           % uint8 type. 
           vidFormat = obj.VideoFormat;
           obj.IsUint8Video = contains(vidFormat, 'Indexed') || ...
                              contains(vidFormat, 'Grayscale') || ...
                              ( contains(vidFormat, 'Mono8') && ...
                                    ~contains(vidFormat, 'Signed') ) || ...
                              ( contains(vidFormat, 'RGB24') && ...
                                    ~contains(vidFormat, 'Signed') );

           % If the file is not a compile time constant, then the datatype
           % cannot be determine at compile time. Hence, only videos that
           % decode to uint8 are supported.
           if ~isFileConst && ~obj.IsUint8Video
               % Perform initialization of sample data even under error
               % conditions. This is done to guard against RunTimeChecks
               % being turned OFF. 
               
               if coder.internal.hasRuntimeErrors()
                   coder.internal.error('multimedia:videofile:coderOnlyUint8Supported');
               else
                   % This branch will be analyzed by Coder only if run-time
                   % checks are turned OFF. This is a recommended coding
                   % pattern to avoid incorrect behaviour due to Coder
                   % optimizations.
                   initRefFramesOnError(obj, vidFormat, isFileConst);
               end
               return;
           end
           
           % In the generated code, if run-time error checks are OFF, code
           % can reach this point even if the video file could not be read.
           % Take no further action if the the file either does not have a
           % video stream or the video stream cannot be read.
           if ~obj.HasVideo
               % Perform initialization of sample data even under error
               % conditions. This is done to guard against RunTimeChecks
               % being turned OFF.  
               
               if coder.internal.hasRuntimeErrors()
                   coder.internal.error('multimedia:videofile:NoVideo');
               else
                   % This branch will be analyzed by Coder only if run-time
                   % checks are turned OFF. This is a recommended coding
                   % pattern to avoid incorrect behaviour due to Coder
                   % optimizations.
                   initRefFramesOnError(obj, vidFormat, isFileConst);
               end
               return;
           end
                      
           % Create representative video frame for AsyncIO. The frame
           % need not contain valid data and so it can be uninitialized
           % memory.
           [numChannels, dtype] = matlab.internal.coder.VideoReader.computeVideoFrameInfo(vidFormat, isFileConst);
           
           if coder.isRowMajor
               sampleData = coder.nullcopy( zeros(obj.Height, obj.Width, numChannels, dtype) );
           else
               sampleData = coder.nullcopy( zeros(numChannels, obj.Width, obj.Height, dtype) );
           end
           
           obj.SampleFrame = struct( 'Data', sampleData, 'Timestamp', NaN );
                                
           % An EmptyFrame is denoted by a NaN value for the Timestamp
           % field
           obj.EmptyFrame = obj.SampleFrame;
           
           % Initialize the cached frame.
           obj.CachedFrame = obj.EmptyFrame;
           
           % Open the channel to start data streaming.
           openChannel(obj);
           
           % Read ahead one frame
           cacheNextFrame(obj);
       end
       
       function delete(obj)
           % Close the channel if open. The channel is opened only when the
           % file contains a supported video stream.
           if obj.Channel.isOpen()
               closeChannel(obj);
               obj.Channel.InputStream.flush();
           end
       end
       
       function vidFrame = readFrameAtPosition(obj, position)
           % This is being added to guard against the scenario of run-time
           % checks being turned OFF.
           if ~obj.HasVideo
               vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
               return;
           end
           
           % Read frame at using a timestamp
           if isa(position, 'double')
               if position < 0
                   if coder.internal.hasRuntimeErrors()
                       coder.internal.error('multimedia:videofile:coderInvalidReadPosition');
                   else
                       % This branch will be executed only when run-time
                       % errors are turned OFF. 
                       vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
                   end
                   return;
               end
               vidFrame = readFrameAtTime(obj, position);
               obj.LastFrameIndexRead = -1;
           elseif isa(position, 'uint64')
               % Read frame at using a frame index
               vidFrame = readFrameAtIndex(obj, double(position));
               
               % If the video frame read is invalid, then do not update the
               % last frame index read.
               if isnan(vidFrame.Timestamp)
                   return;
               end
               obj.LastFrameIndexRead = double(position);
           else
               if coder.internal.hasRuntimeErrors()
                   coder.internal.error('multimedia:videofile:coderInvalidReadPosition');
               else
                   % This branch will be executed only when run-time errors
                   % are turned OFF. 
                   vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
               end
               return;
           end
       end
       
       function vidFrame = readNextFrame(obj)
           % This is being added to guard against the scenario of run-time
           % checks being turned OFF.
           if ~obj.HasVideo
               vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
               return;
           end
           
           % If there are no more frames available to read, then throw an
           % error.
           if ~hasFrame(obj)
               obj.LastFrameIndexRead = -1;
               if coder.internal.hasRuntimeErrors()
                   coder.internal.error('multimedia:videofile:EndOfFile');
               else
                   % This branch will be executed only when run-time errors
                   % are turned OFF. 
                   vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
               end
               return;
           end
            
           % The cached frame can be empty at this point only because an
           % error was received during reading the frame. 
           if isinf(obj.CachedFrame.Timestamp)
               if coder.internal.hasRuntimeErrors()
                   coder.internal.error('multimedia:videofile:ReadFailed');
               else
                   % This branch will be executed only when run-time
                   % errors are turned OFF.
                   vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
               end
               return;
           end
           
           % If the code reaches this point, it indicates the cached frame
           % is a valid frame
           vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.CachedFrame);
           
           % Update the LastTimestampRead property
           obj.LastTimestampRead = vidFrame.Timestamp;
            
           % Update the LastFrameIndexRead property  
           % obj.LastFrameIndexRead = -1 denotes stream based reading
           if obj.LastFrameIndexRead ~= -1
               obj.LastFrameIndexRead = obj.LastFrameIndexRead + 1;
           end
           
           % Read ahead
           cacheNextFrame(obj);
       end
       
       function out = hasFrame(obj)
           % This is being added to guard against the scenario of run-time
           % checks being turned OFF.
           if ~obj.HasVideo
               out = false;
               return;
           end
           
           out = ~isCachedFrameEmpty(obj);
       end
    end
    
    % Getters. All getters are being suitably guarded for the condition
    % when run-time error checks are turned OFF.
    methods            
        function width = get.Width(obj)
            if obj.IsFileConst
                width = obj.VidPropsConstFile.Width;
            else
                if ~obj.HasVideo
                    width = NaN;
                else
                    width = obj.Channel.getCustomProp('Width');
                end
            end
        end
        
        function height = get.Height(obj)
            if obj.IsFileConst
                height = obj.VidPropsConstFile.Height;
            else
                if ~obj.HasVideo
                    height = NaN;
                else
                    height = obj.Channel.getCustomProp('Height');
                end
            end
        end
        
        function fr = get.FrameRate(obj)
            if ~obj.HasVideo
                fr = NaN;
            else
                fr = obj.Channel.getCustomProp('FrameRate');
            end
        end
        
        function dur = get.Duration(obj)
            if ~obj.HasVideo
                dur = NaN;
            else
                dur = obj.Channel.getCustomProp('Duration');
            end
        end
        
        function bpp = get.BitsPerPixel(obj)
            if obj.IsFileConst
                bpp = obj.VidPropsConstFile.BitsPerPixel;
            else
                if ~obj.HasVideo
                    bpp = NaN;
                else
                    bpp = obj.Channel.getCustomProp('BitsPerPixel');
                end
            end
        end
        
        function vf = get.VideoFormat(obj)
            if obj.IsFileConst
                vf = obj.VidPropsConstFile.VideoFormat;
                vf = strip(vf);
            else
                if ~obj.HasVideo
                    vf = '';
                else
                    vf = strip(obj.Channel.getCustomProp('VideoFormat'));
                    % Remove the null terminator
                    vf = vf(1:end-1);
                end
            end
        end
        
        function tsVector = get.Timestamps(obj)
            if ~obj.HasVideo
                tsVector = NaN;
            else
                tsVector = obj.TsHandler.TimeStamps;
            end
        end
        
        function numFrames = get.NumFrames(obj)
            if ~obj.HasVideo
                numFrames = NaN;
            else
                numFrames = numel(obj.Timestamps);
            end
        end
        
        function colorMap = get.Colormap(obj)
            if ~obj.HasVideo || ~obj.Channel.hasCustomProp('Colormap')
                colorMap = NaN;
            else
                % The colormap returned will always have a maximum of 256x3
                % elements.
                colorMap = obj.Channel.getCustomProp('Colormap');
                totalEntries = length(colorMap) / 3;
                
                % The colormap returned is in packed, row-major order.
                % Convert it to MATLAB order.
                colorMap = double( reshape(colorMap, 3, totalEntries)' );
                
                % Discard those entries that are not valid.
                numValidEntries = obj.Channel.getCustomProp('NumColormapEntries');
                colorMap = colorMap(1:numValidEntries, :);
            end
        end

        function tf = get.HasVideo(obj)
            % Return FALSE when
            % (1) Plugin could not successfully read the file AND
            % (2) Input file is not a compile time constant and does not
            % decode to uint8 output type
            if ~obj.IsPluginSuccess || ...
                (~obj.IsFileConst && ~obj.IsUint8Video)
                tf = false;
            else
                tf = obj.Channel.getCustomProp('HasVideo');
            end
        end
        
        function tf = get.HasAudio(obj)
            if ~obj.IsPluginSuccess
                tf = false;
            else
                tf = obj.Channel.getCustomProp('HasAudio');
            end
        end   
        
        function numAudioChannels = get.NumAudioChannels(obj)
            if ~obj.IsPluginSuccess
                numAudioChannels = NaN;
            else
                numAudioChannels = obj.Channel.getCustomProp('NumAudioChannels');
            end
        end
        
        function numColorChannels = get.NumColorChannels(obj)
            if ~obj.HasVideo
                numColorChannels = NaN;
            else
                numColorChannels = obj.Channel.getCustomProp('NumColorChannels');
            end
        end        
        
        function vc = get.VideoCompression(obj)
            if ~obj.HasVideo
                vc = '';
            else
                vc = strip(obj.Channel.getCustomProp('VideoCodec'));
                % Remove the null terminator
                vc = vc(1:end-1);
            end
        end
        
        function ac = get.AudioCompression(obj)
            if ~obj.HasAudio
                ac = '';
            else
                ac = strip(obj.Channel.getCustomProp('AudioCodec'));
                ac = ac(1:end-1);
            end
        end
        
        function tf = get.IsNumFramesAvailable(obj)
            if ~obj.HasVideo
                tf = false;
            else
                tf = obj.TsHandler.IsAllTimeStampsRead;
            end
        end
        
        function isValid = get.IsPluginSuccess(obj)
            % Determine if the plugin was able to successfully read the
            % file. Additional constraints such as output type are coder
            % specific business logic.
            isValid = obj.Channel.getCustomProp('IsPluginSuccess');
        end
    end
    
    methods(Access='private')
        
        function createChannel(obj, fileName, isComputeTSOnObjCreation)
            
            % Specify the names, sizes and types of all the possible
            % properties that can be returned upon opening the file. Each
            % plugin might not return all of the properties.
            fileProps.Height = 0;
            fileProps.Width = 0;
            fileProps.FrameRate = 0;
            fileProps.Duration = 0;
            fileProps.BitsPerPixel = 0;
            fileProps.VideoFormat = blanks(20);
            fileProps.HasVideo = true;
            fileProps.HasAudio = true;
            fileProps.NumAudioChannels = 0;
            fileProps.NumColorChannels = 0;
            fileProps.VideoCompression = blanks(20);
            fileProps.AudioCompression = blanks(20);
            fileProps.NumFrames = 0;
            fileProps.IsPluginSuccess = false;
            % The plugins return colormap as a linear uint8 array having a
            % maximum size of 256*3 elements.
            fileProps.Colormap = zeros(256*3, 1, 'uint8');
            % The number of colormap entries can be less than 256. The
            % plugin has to provide this information.
            fileProps.NumColormapEntries = 0;
            
            % This type of this variable needs to be defined. Otherwise,
            % assigning fullName using a call to extrinsic functions
            % results in an mxArray. Any function that is called using
            % fullName as an input is treated as an extrinsic which also
            % produces an mxArray as an output.
            fullName = matlabshared.asyncio.internal.coder.computeAbsolutePath(fileName);
            
            % Specify that the full filename is of variable size. 
            % The varsize is ignored in MATLAB.
            coder.varsize('fullName', [], [0 1]);
            
            coder.extrinsic('multimedia.internal.io.absolutePathForReading');
            
            if coder.internal.canUseExtrinsic()
                % Need to allow users to specify a partial path to the
                % video file.
                fullName = multimedia.internal.io.absolutePathForReading(...
                                fileName, ...
                                'multimedia:videofile:FileNotFound', ...
                                'multimedia:videofile:FilePermissionDenied' );
            else
                fullName = matlabshared.asyncio.internal.coder.computeAbsolutePath(fileName);
                % If the file could not be found, then an empty character
                % vector is returned.
                if isempty(fullName)
                    if coder.internal.hasRuntimeErrors()
                        coder.internal.error('multimedia:videofile:FileNotFound');                    
                    else
                        % Use the file name as provided by the user.
                        fullName = fileName;
                    end
                else
                    % Test whether read permissions are available to the file.
                    fp = fopen(fullName, 'r');
                    if fp == -1
                        if coder.internal.hasRuntimeErrors()
                            coder.internal.error('multimedia:videofile:FilePermissionDenied');
                        else
                            % Use the file name as provided by the user.
                            fullName = fileName;
                        end
                    else
                        fclose(fp);
                    end
                end
                % If the file was not found or does not have read
                % permissions, allowing the execution if run-time checks
                % have been turned OFF to continue because this will result
                % in the channel not being created successfully.
            end
            % By this point, fullName is either the full path to the file
            % or an empty character.
            
            obj.updateNameAndPath(fullName);
            
            % Query the hardware acceleration setting
            coder.extrinsic('matlab.internal.video.isHardwareAccelerationUsed');
            isHwAccelUsed = coder.const(matlab.internal.video.isHardwareAccelerationUsed);
            
            % Specify the init options to create the channel to read
            % frames. Any options not required for a device plugin will be
            % ignored by it. 
            initOptions.Filename = fullName;
            initOptions.IsErrorOnInitFail = false;
            initOptions.UseHardwareAcceleration = isHwAccelUsed;
            
            % Get the list of all the device plugins available on the
            % system. The list of plugins is in sorted priority order.
            [dPluginList, cPlugin, nPlugin] = ...
                            matlab.internal.coder.VideoReader.getPluginsToUse();
           
            % For RTW targets, the full path to the plugins might not be
            % valid. We need to validate these paths. If matlabroot does
            % not exist, then we assume that the plugins are in the current
            % working directory
            if coder.target('RTW')
                [devicePluginList, converterPlugin, nullPlugin] = ...
                            matlab.internal.coder.VideoReader.determineValidPluginPath( ...
                                            dPluginList, ...
                                            cPlugin, ...
                                            nPlugin );
            else
                devicePluginList = dPluginList;
                converterPlugin = cPlugin;
                nullPlugin = nPlugin;
            end
            
            % Specify the init options to create the time-stamp channel.
            % The hardware acceleration is required 
            tsInitOptions.Filename = fullName;
            tsInitOptions.PluginMode = coder.const('Counting');
            tsInitOptions.UseHardwareAcceleration = isHwAccelUsed;
            
            % Select the Device Plugin that supports reading this file
            coder.unroll();
            for cnt = 1:numel(devicePluginList)
                devicePlugin = devicePluginList{cnt};
                % Prepare coderExampleData for creating Channel Object.
                % VidPropsConstFile property gets the Video File information
                % at Compile Time. Hence using it to fetch the Format and
                % then the type of data used in the file.
                [~, dtype] = coder.const(@matlab.internal.coder.VideoReader.computeVideoFrameInfo, strip(obj.VidPropsConstFile.VideoFormat), obj.IsFileConst);
                sampleData = coder.nullcopy( zeros(3, 3, 3, dtype) );
                initialSampleFrame = struct( 'Data', sampleData, 'Timestamp', NaN );
                obj.Channel = matlabshared.asyncio.internal.Channel( devicePlugin,...
                                               converterPlugin,...
                                               CountDimensions = [2 2],...
                                               Options = initOptions, ...
                                               StreamLimits = [obj.NumFramesToBuffer 1],...
                                               CustomPropsExpected = fileProps, ...
                                               CoderExampleData = initialSampleFrame);
                if obj.IsPluginSuccess
                    % Create the timestamp channel only if a valid device
                    % plugin was found.
                    tsPlugin = matlab.internal.coder.VideoReader.determineTimeStampPlugin(devicePlugin, nullPlugin);
                    obj.initTsHandler( obj.Duration, obj.FrameRate, ...
                                       tsPlugin, converterPlugin, ...
                                       tsInitOptions, ...
                                       isComputeTSOnObjCreation );
                    return;
                end
            end
            
            % If none of the plugins are able to open the file, then throw
            % a suitable error message.
            if ~obj.IsPluginSuccess
                coder.internal.error('multimedia:videofile:coderFileNotSupported');
                return;
            else
                % This portion of the code will not be reached. This is
                % being done to make coder happy.
                obj.initTsHandler( coder.ignoreConst(4), coder.ignoreConst(30), ...
                                   nullPlugin, converterPlugin, tsInitOptions, false );
            end
        end
        
        
        function openChannel(obj, startPosition)
            % Open the channel only if a supported video stream is present
            % in the file.
            if ~obj.HasVideo
                return;
            end
            
            if obj.Channel.isOpen()
                return;
            end
            
            % Seek to the specified position upon opening the channel.
            % Configure the device plugins to return row-major interleaved
            % data to improve performance. Even if row-major codegen is not
            % being done, keeping the data in row-major interleaved order
            % until necessary will help improve performance.
            openOptions.IsOutputRowMajorInterleaved = true;
            if nargin == 2
                openOptions.ReadPosition = startPosition;
            end
            obj.Channel.open(openOptions);
        end
        
        function closeChannel(obj)
            % The channel is opened only if there is a supported video
            % stream present in it.
            if obj.Channel.isOpen()
                obj.Channel.close();
            end
        end
        
        function vidFrame = readFrameAtTime(obj, timeLoc)
            % Negative values of time are permitted because of certain
            % files which have negative timestamps. 
           
            % Timestamp specified can be anywhere in the file and so the
            % cached frame is no longer valid.
            obj.CachedFrame = obj.EmptyFrame;
                                
            % Close channel so it can be re-opened with
            % updated options
            closeChannel(obj);
            
            % Flush the input stream for any data remaining from the 
            % last read
            obj.Channel.InputStream.flush();
   
            % Open channel and seek to specific location
            openChannel(obj, timeLoc);
            
            % Read ahead to cache the next frame
            cacheNextFrame(obj);

            % Return the frame
            vidFrame = readNextFrame(obj);
        end
        
        function vidFrame = readFrameAtIndex(obj, index)
            % Returns the video frame that is the (index)th frame in the
            % video. index should be a positive integer
            
            % If the frame index requested is the next frame to be read,
            % then there is no need to reposition the channel.
            if index == obj.LastFrameIndexRead+1
                vidFrame = readNextFrame(obj);
                return;
            end
            
            % Get the timestamp corresponding to the index requested.
            ts = obj.TsHandler.getTimeStampAtIndex(index);
            
            if isnan(ts)
                if coder.internal.hasRuntimeErrors()                             
                    coder.internal.error('multimedia:videofile:invalidFrameIndex');
                else
                    vidFrame = matlab.internal.coder.VideoReader.transformFrame(obj.EmptyFrame);
                end
                return;
            end
            vidFrame = readFrameAtTime(obj, ts);
        end
        
        function cacheNextFrame(obj)
            if ~obj.HasVideo
                return;
            end
            
            % This call to read can return the following values:
            % No frames: Indicates that end-of-file has been reached
            % Error Frame i.e. Timestamp = Inf. Indicates an error occurred
            % when reading the frame
            % Valid Frame i.e. Timestamp ~= Inf.
            [vidFrame, numFramesRead] = obj.Channel.InputStream.read(1, obj.SampleFrame);
            if numFramesRead == 0                
                obj.CachedFrame = obj.EmptyFrame;
            else
                % The indexing into vidFrame is necessary because the RHS
                % in general is a variable size vector but the LHS is a 1x1
                % vector. MATLAB Coder does not permit this.
                obj.CachedFrame = vidFrame(1);
            end
        end
        
        function initTsHandler(obj, fileDur, frameRate, tsPlugin, ...
                            convPlugin, tsInitOptions, isComputeTSOnObjCreation )
            obj.TsHandler = ...
                matlab.internal.coder.TimeStampManager( fileDur, frameRate, ...
                                    tsPlugin, convPlugin, tsInitOptions, ...
                                    isComputeTSOnObjCreation );
        end
        
        function tf = isCachedFrameEmpty(obj)
            tf = isnan(obj.CachedFrame.Timestamp); 
        end
        
        function updateNameAndPath(obj, fullName)
            [obj.Name, obj.Path] = matlab.internal.coder.API.fileparts(fullName);
        end
        
        function initRefFramesOnError(obj, vidFormat, isFileConst)
            [numChannels, dtype] = matlab.internal.coder.VideoReader.computeVideoFrameInfo(vidFormat, isFileConst);
            
            % If the file name is a compile time constant, then its
            % dimensions are fixed. Also, if the filename is a compile-time
            % constant, we validate it at compile time
            if isFileConst
                height = obj.Height;
                width = obj.Width;
            else
                % This is being done to make coder happy. Randomizing the
                % inputs ensures that the dimesions of arrays used for
                % timestamp handling are not resolved as compile time
                % constants. This will ensure a 0x0 matrix. 
                height = coder.ignoreConst(0);
                width = coder.ignoreConst(0);
            end
            if coder.isRowMajor
                sampleData = coder.nullcopy( zeros(height, width, numChannels, dtype) );
            else
                sampleData = coder.nullcopy( zeros(numChannels, width, height, dtype) );
            end
            
            obj.SampleFrame = struct( 'Data', sampleData, 'Timestamp', NaN );
            obj.EmptyFrame = obj.SampleFrame;
            obj.CachedFrame = obj.EmptyFrame;
        end
    end
    
    methods (Static, Hidden)
        % Specify the properties of the class that will not be modified
        % after the first assignment. This is being done to ensure that the
        % dimensions are reported as constant when the input file name is a
        % compile time constant.
        function p = matlabCodegenNontunableProperties(~)
            p = {'IsFileConst', 'VidPropsConstFile'};
        end
    end
    
    
    methods(Access='private', Static)
        function [pluginsToUse, converterPlugin, nullPlugin] = getPluginsToUse()
            coder.extrinsic('matlab.internal.coder.getPlugins');
            [p, c, n] = matlab.internal.coder.getPlugins();
            
            pluginsToUse = coder.const(p);
            converterPlugin = coder.const(c);
            nullPlugin = coder.const(n);
        end
        
        function [dplugins, cPlugin, nPlugin] = determineValidPluginPath( ...
                                                    devicePluginList, ...
                                                    converterPlugin, ...
                                                    nullPlugin )                                
            % Helper function that validates the path to shared libraries
            % and updates them suitably.
            
            dplugins = cell(numel(devicePluginList), 1);
            for cnt = 1:numel(devicePluginList)
                dplugins{cnt} = matlab.internal.coder.API.resolveValidPath(devicePluginList{cnt});
            end
            cPlugin = matlab.internal.coder.API.resolveValidPath(converterPlugin);
            nPlugin = matlab.internal.coder.API.resolveValidPath(nullPlugin);
        end
                
        function tsPlugin = determineTimeStampPlugin(devicePlugin, nullPlugin)            
            if contains(devicePlugin, 'mj2000') || ...
                    contains(devicePlugin, 'mjpegavi')
                tsPlugin = nullPlugin;
                return;
            end
            
            % The Media Foundation and DirectShow plugins use the same
            % shared library as both the device and the time stamp plugins.
            if contains(devicePlugin, 'mfreader') || ...
                    contains(devicePlugin, 'directshow')
                tsPlugin = devicePlugin;
                return;
            end
            
            % If code reaches this point, it indicates that it is either
            % the Gstreamer or AVFoundation plugin
            tsPlugin = insertBefore(devicePlugin, 'reader', 'timestamp');
        end
        
        function numChannels = computeNumColorChannels(vidFormat)
            if contains(vidFormat, 'RGB')
                numChannels = 3;
            else
                numChannels = 1;
            end
        end
        
        function dtype = computeFrameDataType(vidFormat)
            switch vidFormat
                case {'Mono8 Signed', 'RGB24 Signed'}
                    dtype = 'int8';
                case {'Mono16', 'RGB48'}
                    dtype = 'uint16';
                case {'Mono16 Signed', 'RGB48 Signed'}
                    dtype = 'int16';
                otherwise
                    dtype = 'uint8';
            end
        end
        
        function [numChannels, dtype] = computeVideoFrameInfo(vidFormat, isFileConst)
            numChannels = matlab.internal.coder.VideoReader.computeNumColorChannels(vidFormat);
            if isFileConst
                dtype = coder.const(matlab.internal.VideoReader.computeFrameDataType(vidFormat));
            else
                dtype = coder.const('uint8');
            end
        end
        
        function vidFrame = transformFrame(inputFrame)            
            % The video frame data from the underlying framework is in
            % row-major interleaved layout.
            if coder.isColumnMajor
                % If column-major codegen is required, then data has to be
                % transformed into column-major layout. 
                vidFrame = matlab.internal.coder.API.permute(inputFrame);
            else
                vidFrame = inputFrame;
            end
        end
        
    end
end
