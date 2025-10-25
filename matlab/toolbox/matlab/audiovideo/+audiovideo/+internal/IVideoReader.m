%#codegen
classdef IVideoReader < handle
    % audiovideo.internal.IVideoReader Abstract base class for VideoReader.
    % This class contains methods, properties and helpers that are shared
    % between the MATLAB and Codegen versions of VideoReader
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    %------------------------------------------------------------------
    % General properties (in alphabetic order)
    %------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='private', Dependent)
        Duration        % Total length of file in seconds.
        Name            % Name of the file to be read.
        Path            % Path of the file to be read.
    end
    
    %------------------------------------------------------------------
    % Video properties (in alphabetic order)
    %------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='private', Dependent)
        BitsPerPixel    % Bits per pixel of the video data.
        FrameRate       % Frame rate of the video in frames per second.
        Height          % Height of the video frame in pixels.
        NumFrames       % Total number of frames in the video stream.
        VideoFormat     % Video format as it is represented in MATLAB.
        Width           % Width of the video frame in pixels.
    end
    
    properties(GetAccess='public', SetAccess='public')
        Tag = '';       % Generic string for the user to set.
        UserData = [];       % Generic field for any user-defined data.
    end
    
    properties(GetAccess='public', SetAccess='public', Dependent)
        CurrentTime     % Location, in seconds, from the start of the 
                        % file of the current frame to be read.
    end
    
    %------------------------------------------------------------------
    % Undocumented properties
    %------------------------------------------------------------------
    properties(GetAccess='public', SetAccess='private', Dependent, Hidden)
        AudioCompression
        NumberOfAudioChannels
        VideoCompression
        NumberOfFrames      % Total number of frames in the video stream.
    end
    
    %------------------------------------------------------------------
    % Private properties
    %------------------------------------------------------------------
    properties(Access='protected')        
        % Stores the CurrentTime.
        % This applies to time-based reading only. This reflects the
        % CurrentTime value that was explicitly set by the user.
        InternalCurrentTime = NaN;
        
        % Next frame index to read
        % This applies to frame-based reading.
        % If the value is NaN, it means this property has been invalidated.
        NextFrameIndexToRead = 1;        
        
        % The next frame in the video file. This is cached to accurately
        % report the CurrentTime value.
        StoredFrame;
        
        % Denotes an empty frame. This hs the same type as as the
        % StoredFrame but with the Timestamp field having a NaN value.
        EmptyFrame;
        
        % Denotes an empty numeric matrix that is output from the
        % read/readFrame methods. This is used primarily for the codegen
        % implementation
        EmptyOutput;
    end
    
    properties(Access='protected', Transient)
        % Underlying implementation object.
        VidReader;

        % Stores the MATLAB type of the output matrix. This is computed
        % once during construction as this will not change for a specific
        % file.
        MLTypeInternal;
    end
    
    properties(Access='protected', Dependent)
        % MATLAB Datatype of the numeric matrix that represents the video
        % data
        MLType;
    end
    
    properties(Access='protected', Constant)
        % To help support future forward compatibility. This is the MATLAB
        % version in which a significant change is made to the VideoReader
        % object implementation.
        SchemaVersion = 9.7;
        
        ErrorWarnPrefix = 'MATLAB:audiovideo';
    end
    
    %------------------------------------------------------------------
    % Documented methods
    %------------------------------------------------------------------
    methods(Access='public')
        %------------------------------------------------------------------
        % Lifetime
        %------------------------------------------------------------------
        function obj = IVideoReader(fileName, varargin)
            % If no file name provided.
            if nargin == 0
                errorID = 'MATLAB:audiovideo:VideoReader:noFile';
                audiovideo.internal.IVideoReader.throwError(errorID);
                cleanupOnError(obj);
                return;
            end
                
            currentTime = parseCreationArgs(obj, varargin{:});
            
            % In MATLAB code, an exception will be generated if an invalid
            % CurrentTime is provided.
            if currentTime < 0
                errorID = 'MATLAB:audiovideo:VideoReader:coderInvalidCurrentTime';
                audiovideo.internal.IVideoReader.throwError(errorID);
                cleanupOnError(obj);
                return;
            end
            
            % Convert filename to char array
            fileName = convertStringsToChars(fileName);
            
            % Initialize the object.
            % The duration of the file needs to be determined before the
            % CurrentTime can be set.
            initReader(obj, fileName, currentTime);
        end
        
        %------------------------------------------------------------------
        % Operations
        %------------------------------------------------------------------
        function outputFrames = read(obj, varargin)            
            validateattributes(obj, {'VideoReader'}, {}, 'VideoReader.read');
            
            if ~hasVideo(obj)
                outputFrames = obj.EmptyOutput;
                return;
            end
            
            % Verify that the index argument is of numeric type
            % Corresponds to the syntax: read(obj)
            if nargin == 1 
                videoFrames = readFramesUntilEnd(obj);
                outputFormat = 'default';

            % Corresponds to the syntax: read(obj, 'native')
            elseif nargin == 2 && (ischar(varargin{1}) || isstring(varargin{1}))
                % Specifying the output format is not supported in
                % generated code
                if ~coder.target('MATLAB')
                    coder.internal.error('MATLAB:audiovideo:VideoReader:coderNoNativeOrDefault', 'READ');
                    outputFrames = obj.EmptyOutput;
                    return;
                end
                
                outputFormat = determineReadOutputFormat(obj, 'VideoReader.read', varargin{1});
                
                videoFrames = readFramesUntilEnd(obj);

            % Corresponds to the syntax: read(obj, index)
            elseif nargin == 2 && ~ischar(varargin{1})
                validateattributes( varargin{1}, {'numeric'}, ...
                                    {'vector', 'nonnan', 'positive'},...
                                    'VideoReader.read', 'index' );

                videoFrames = readFramesInIndexRange(obj, varargin{1});
                outputFormat = 'default';

            % Corresponds to the syntax: read(obj, index, 'native')
            elseif nargin == 3
                % Specifying the output format is not supported in
                % generated code
                if ~coder.target('MATLAB')
                    coder.internal.error('MATLAB:audiovideo:VideoReader:coderNoNativeOrDefault', 'READ');
                    outputFrames = obj.EmptyOutput;
                    return;
                end
                
                validateattributes( varargin{1}, {'numeric'}, ...
                                    {'vector', 'nonnan', 'positive'},...
                                    'VideoReader.read', 'index' );
                
                outputFormat = determineReadOutputFormat(obj, 'VideoReader.read', varargin{2});

                videoFrames = readFramesInIndexRange(obj, varargin{1});
            else
                if coder.target('MATLAB')
                    % ensure that we pass in 1 or 2 arguments only
                    narginchk(1, 2);
                else
                    % ensure that we pass in 1, 2 or 3 arguments only
                    narginchk(1, 3);
                end
            end
            
            if isempty(videoFrames)
                outputFrames = obj.EmptyOutput;
                return;
            end
            
            videoFrames = audiovideo.internal.IVideoReader.convertToOutputFormat( videoFrames, ...
                                                             obj.VideoFormat, ...
                                                             outputFormat, ...
                                                             obj.VidReader, ...
                                                             obj.MLType );

            % Video is the output argument.
            outputFrames = videoFrames;
        end
        
        function outputFrame = readFrame(obj, varargin)
            if coder.target('MATLAB')
                % ensure that we pass in 1 or 2 arguments only
                narginchk(1, 2);
            else
                % Remove `coder.inline('never')` once g2404539 is fixed.
                coder.inline('never');
                if nargin == 2
                    coder.internal.error('MATLAB:audiovideo:VideoReader:coderNoNativeOrDefault', 'READFRAME');
                    outputFrame = obj.EmptyOutput;
                    return;
                end
            end
            
            % Get the Output format to be used
            outputformat = determineReadOutputFormat(obj, 'VideoReader.readFrame', varargin{:});
            
            % If there are no more frames available to read, generate an
            % error for the user
            isEof = ~hasFrameLite(obj);
            if isEof
                origErrorID = 'multimedia:videofile:EndOfFile';
                if coder.target('MATLAB')
                    msg = message(origErrorID);
                    errorID = replace( msg.Identifier, 'multimedia:videofile', ...
                                    [VideoReader.ErrorWarnPrefix ':VideoReader'] );

                    throwAsCaller( MException(errorID, msg.getString()) );
                else
                    if coder.internal.hasRuntimeErrors()
                        outputFrame = obj.EmptyOutput;
                        
                        % Display the same error ID as in the MATLAB case.
                        newErrorID = replace( origErrorID, 'multimedia:videofile', ...
                                        [audiovideo.internal.IVideoReader.ErrorWarnPrefix ':VideoReader'] );
                        coder.internal.errorIf(isEof, 'CatalogID', origErrorID, 'ReportedID', newErrorID);
                    else
                        outputFrame = obj.EmptyOutput;
                    end
                    return;
                end
            end
            
            % Perform any follow up action such as throwing a cached
            % exception depending upon the target.
            postReadFrameAction(obj);
            
            % The data read at this point are numeric matrices. Depending
            % upon the output format, these will be converted into FRAME
            % structs.
            outputFrame = audiovideo.internal.IVideoReader.convertToOutputFormat( obj.StoredFrame.Data, ...
                                                                           obj.VideoFormat, ...
                                                                           outputformat, ...
                                                                           obj.VidReader, ...
                                                                           obj.MLType );
            
            % Read ahead to cache the next frame.
            cacheFrame(obj);
            
            % Update the index of the next frame to read. The value will
            % update only if it is not invalidated.
            obj.NextFrameIndexToRead = obj.NextFrameIndexToRead + 1;
        end
                
        function flag = hasFrame(obj)
            % ensure that we pass in only 1 argument
            narginchk(1, 1);

            % ensure that we pass out only 1 output argument
            nargoutchk(0, 1);

            flag = hasFrameLite(obj);
        end
    end
    
    methods(Abstract, Access='public')
        inspect(obj);
        obj = saveobj(obj);
    end
    
        
    %------------------------------------------------------------------
    % Custom Getters/Setters
    %------------------------------------------------------------------
    methods
        % Properties that are dependent on underlying object.
        function value = get.Duration(obj)
            if coder.target('MATLAB')
                % In MATLAB, MIVR returns the file duration as a duration
                % type. Hence, this conversion is necessary.
                value = seconds(obj.VidReader.Duration);
            else
                value = obj.VidReader.Duration;
            end

            % Duration property is set to empty if it cannot be determined
            % from the video. Generate a warning to indicate this.
            if isempty(value)
                warnState=warning('off','backtrace');
                c = onCleanup(@()warning(warnState));
                warning(message('multimedia:videofile:unknownDuration'));
            end
        end
        
        function value = get.Name(obj)
            value = obj.VidReader.Name;
        end
                        
        function value = get.Path(obj)
            value = obj.VidReader.Path;
        end
                        
        function value = get.BitsPerPixel(obj)
            value = obj.VidReader.BitsPerPixel;
        end
                        
        function value = get.FrameRate(obj)
            value = obj.VidReader.FrameRate;
        end
                        
        function value = get.Height(obj)
            value = obj.VidReader.Height;
        end
                
        function value = get.NumFrames(obj)
            % Query the infrastructure for the number of frames present in
            % the video file.
            value = obj.VidReader.NumFrames;
        end
               
        function value = get.VideoFormat(obj)
            value = obj.VidReader.VideoFormat;
        end
                        
        function value = get.Width(obj)
            value = obj.VidReader.Width;
        end
                
        function value = get.AudioCompression(obj)
            value = obj.VidReader.AudioCompression;
        end
                        
        function value = get.NumberOfAudioChannels(obj)
            value = obj.VidReader.NumAudioChannels;
        end
                
        function value = get.VideoCompression(obj)
            value = obj.VidReader.VideoCompression;
        end
        
        function val = get.NumberOfFrames(obj)
            val = obj.NumFrames;
        end
                
        function value = get.CurrentTime(obj)
            % This is needed to ensure that the CurrentTime is reported
            % exactly as the value set by the user on all platforms for all
            % file formats. This is to account for the difference in
            % seeking behaviour across platforms and frameworks.
            if ~isnan(obj.InternalCurrentTime)
                value = obj.InternalCurrentTime;
                return;
            end
            
            % After object creation, StoredFrame can be empty only if
            % end-of-file has been reached
            if isStoredFrameEmpty(obj)
                value = obj.Duration;
                return;
            end
            
            if coder.target('MATLAB')
                % In MATLAB, MIVR returns the TimeStamp field as a duration
                % type. Hence, this conversion is necessary.
                value = seconds(obj.StoredFrame.Timestamp);
            else
                value = obj.StoredFrame.Timestamp;
            end
        end
        
        function set.CurrentTime(obj, timeInSecs)
            % If the Duration of the video file is known, then check that
            % the time being seeked to is within the duration.
            if ~isempty(obj.Duration)
                validateattributes( timeInSecs, {'double'}, ...
                        {'scalar', 'nonnegative', '<=', obj.Duration}, ...
                        'set', 'CurrentTime');
            end
            
            % As the timestamp can refer to any frame in the video stream,
            % the index of the next frame to read has to be invalidated.
            obj.NextFrameIndexToRead = NaN;
            
            % Cache the next frame
            cacheFrame(obj, timeInSecs);
        end
        
        % Properties that are not dependent on underlying object.
        function set.Tag(obj, value)
            validateattributes( value, {'char', 'string'}, {}, 'set', 'Tag');
            obj.Tag = value;
        end
        
        function type = get.MLType(obj)
            type = obj.MLTypeInternal;
        end
    end
    
    %------------------------------------------------------------------
    % Undocumented methods
    %------------------------------------------------------------------
    methods (Access='public', Hidden)
        %------------------------------------------------------------------
        % Operations
        %------------------------------------------------------------------
        function result = hasAudio(obj)
            result = obj.VidReader.HasAudio;
        end
        
        function result = hasVideo(obj)
            result = obj.VidReader.HasVideo;
        end
    end
    
    %------------------------------------------------------------------
    % Abstract methods
    %------------------------------------------------------------------
    % The implementation of these operations vary depending upon the target
    % due to a limited subset of MATLAB functionality available during code
    % generation. Additionally, the functionality for generated code might
    % be different from MATLAB code.
    methods(Abstract, Access='protected')
        % Parse any name-value pairs provided during object construction
        % and identify the current Time value provided.
        currTime = parseCreationArgs(obj, varargin);
        
        % Initialize the MIVR to perform reading.
        initReader(obj, fileName, currentTime);
        
        % Initialize the empty frame to be used
        createEmptyFrame(obj);
        
        % Update the frame cache by reading one frame ahead. If a valid
        % time stamp (i.e. not NaN) is provided, it reads and caches the
        % frame at that timestamp. If not, it reads and caches the next
        % frame.
        cacheFrameTargetImpl(obj, timeInSecs);
        
        % Determine the mode of reading frames from the video file. 
        outputFormat = determineReadOutputFormat(obj, callerFcn, varargin);
        
        % When reading a range of frames, determine suitable action when
        % all frames in the range could not be read.
        checkIncompleteRead(obj, actNumFramesRead, frameRangeToRead);
        
        % Determine if there are more frames available for reading.
        flag = hasFrameLite(obj);
    end
    
    %------------------------------------------------------------------
    % Helper methods: Cannot be overridden by subclasses
    %------------------------------------------------------------------
    methods(Access='protected', Sealed)
        function postInit(obj, currentTime)
            % The mechanism for determining this value is slight different
            % in codegen
            obj.MLTypeInternal = getMLType(obj);
            
            createEmptyFrame(obj);
            obj.StoredFrame = obj.EmptyFrame;
            
            % Seek to the time location specified
            if ~isnan(currentTime)
                obj.CurrentTime = currentTime;
            else
                % If no time location is specified, pre-roll to the start
                % of the video by reading the next available frame.
                cacheFrame(obj);
            end
        end
        
        function tf = isStoredFrameEmpty(obj)
            tf = isnan(obj.StoredFrame.Timestamp);
        end
        
        function cacheFrame(obj, timeInSecs)
            if nargin == 1
                timeInSecs = NaN;
            end
            
            % Discard the frame that was stored
            obj.StoredFrame = obj.EmptyFrame;
            
            cacheFrameTargetImpl(obj, timeInSecs);
           
            obj.InternalCurrentTime = timeInSecs;
        end
        
        function checkIfIndexOutOfRange(obj, index)
        % This function checks if the index provided exceeds the total
        % number of frames in the video. This is a deferred test since
        % getting the total number of frames imposes performance penalty.

            audiovideo.internal.IVideoReader.validateIndex(index);
            
            numFrames = obj.NumFrames;
            index(isinf(index)) = numFrames;

            if any(index > numFrames)
                errorID = 'MATLAB:audiovideo:VideoReader:invalidFrameIndex';
                audiovideo.internal.IVideoReader.throwError(errorID);
                return;
            end
        end
        
        function reset(obj)
            % Reset the object to its initial state
            obj.StoredFrame = obj.EmptyFrame;
            obj.NextFrameIndexToRead = NaN;
            resetImpl(obj);
        end
    end
    
    %------------------------------------------------------------------
    % Helper methods: Can be overridden by subclasses
    %------------------------------------------------------------------
    methods(Access='protected')
        function cleanupOnError(~)
            % Do nothing. Sub-classes can decide to override this
        end
        
        % Target specific operations when resetting the object
        function resetImpl(~)
            % Do nothing. Sub-classes can decide to override this
        end
        
        function postReadFrameAction(~)
            % Do nothing. Sub-classes can decide to override this
        end
        
        % The supported datatypes are different in generated code.
        function val = getMLType(obj)
            val = audiovideo.internal.IVideoReader.computeFrameDatatype(obj.VideoFormat);
        end
        
        function videoFrames = readFramesUntilEnd(obj, startIndex)
            if nargin == 1
                startIndex = 1;
            end

            % This value is required only to pre-allocate the output matrix and so an
            % approximate value is sufficient as the array can be grown or shrunk as
            % needed.
            estNumFrames = ceil(obj.Duration*obj.FrameRate);

            vidHeight = obj.Height;
            vidWidth = obj.Width;
            numChannels = audiovideo.internal.IVideoReader.computeNumColorChannels(obj.VideoFormat);
            
            numFramesRequested = estNumFrames - startIndex + 1;
            videoFrames = zeros([vidHeight vidWidth numChannels numFramesRequested], obj.MLType);
            
            % Track the actual number of frames that were read from the file.
            actNumFramesRead = 0;
            if obj.NextFrameIndexToRead == startIndex
                vid = obj.StoredFrame;
            else
                obj.StoredFrame = obj.EmptyFrame;
                vid = readFrameAtPosition(obj, startIndex);
            end
            
            % Check whether the frame read in was valid. This check guards
            % against the scenario when there was an error in reading the
            % frame but error checking was turned OFF. This applies only
            % for code generation.
            if isnan(vid.Timestamp)
                videoFrames = obj.EmptyOutput;
                return;
            end
            
            actNumFramesRead = actNumFramesRead + 1;

            videoFrames(:,:,:, 1) = vid.Data;

            while hasFrame( obj.VidReader )
                vid = readNextFrame(obj.VidReader);
                if isnan(vid.Timestamp)
                    videoFrames = obj.EmptyOutput;
                    return;
                end
                actNumFramesRead = actNumFramesRead + 1;
                videoFrames(:,:,:, actNumFramesRead) = vid.Data;
            end

            % As we have read until the end of the file, the number of
            % frames must have been computed
            numFrames = obj.NumFrames;

            if (estNumFrames ~= numFrames) || ...
                    (actNumFramesRead < numFrames - startIndex + 1)
                videoFrames = videoFrames(:,:,:,1:actNumFramesRead);
            end

            % Generate a warning if the actual number of frames read is
            % fewer than the expected total number of frames. 
            checkIncompleteRead(obj, actNumFramesRead, [startIndex numFrames]);
            
            % We have read until the end of the file. Invalidate the
            % index of next frame to read.
            obj.NextFrameIndexToRead = NaN;
        end
        
        function videoFrames = readFramesInIndexRange(obj, indexRange)
            % Basic index validation
            audiovideo.internal.IVideoReader.validateIndex(indexRange); 
            
            if isscalar(indexRange)
                videoFrames = readSingleFrame(obj, indexRange);
            else
                videoFrames = readFrameSequence(obj, indexRange);
            end
        end
        
        function videoFrame = readSingleFrame(obj, index)
            % The last frame is being read
            if isinf(index)
                index = obj.NumFrames;
            else
                % Basic index validation
                VideoReader.validateIndex(index);
            end
            
            videoFrame = readFrameAtIndex(obj, index);
        end
        
        function videoFrame = readFrameAtIndex(obj, index)
            % If the read index is the next frame, that frame has already been
            % stored and so there is no reason to seek.
            if obj.NextFrameIndexToRead == index 
                videoFrame = obj.StoredFrame.Data;
            else
                videoFrame = readFrameAtPosition(obj, index);
                if isnan(videoFrame.Timestamp)
                    videoFrame = obj.EmptyOutput;
                    return;
                else
                    videoFrame = videoFrame.Data;
                end
            end
            
            % Update the index of the next frame to read
            obj.NextFrameIndexToRead = index + 1;

            cacheFrame(obj);
        end
        
        function videoFrames = readFrameSequence(obj, indexRange)

            % Indicates that only one frame is requested
            if indexRange(1) == indexRange(2)
                videoFrames = readSingleFrame(obj, indexRange(1));
                return;
            end

            % Indicates that the entire video is requested
            if isequal(indexRange, [1 Inf]) || isinf(indexRange(2))
                videoFrames = readFramesUntilEnd(obj, indexRange(1));
                return;
            end

            vidHeight = obj.Height;
            vidWidth = obj.Width;
            numChannels = audiovideo.internal.IVideoReader.computeNumColorChannels(obj.VideoFormat);
            
            numFramesRequested = indexRange(2) - indexRange(1) + 1;
            videoFrames = zeros([vidHeight vidWidth numChannels numFramesRequested], obj.MLType);

            % Using a WHILE loop because the cnt is used after the loop. If
            % a FOR-loop is used, then MATLAB Coder generates a warning
            % when a loop variable is used outside the loop.
            cnt = indexRange(1);
            while cnt <= indexRange(2)
                videoFrames(:, :, :, cnt - indexRange(1)+1) = readFrameAtIndex(obj, cnt);
                cnt = cnt + 1;
            end

            actNumFramesRead = cnt - indexRange(1) + 1;
            checkIncompleteRead(obj, actNumFramesRead, indexRange);
        end
    end
    
    %------------------------------------------------------------------
    % Helper methods: Used by the base class only
    %------------------------------------------------------------------
    methods(Access='private')
        function frame = readFrameAtPosition(obj, frameIndex)
            % As duration type is not currently supported in generated
            % code, the MIVR uses uint64 to denote a frame index
            if coder.target('MATLAB')
                frame = readFrameAtPosition(obj.VidReader, frameIndex);
            else
                frame = readFrameAtPosition(obj.VidReader, uint64(frameIndex));
            end
        end
    end
    
    %------------------------------------------------------------------
    % Static helpers: Used by the base class only
    %------------------------------------------------------------------
    methods (Static, Access='private')
        function outputFrames = convertToOutputFormat( inputFrames, inputFormat, outputFormat, vidReader, mltype)
            switch outputFormat
                case 'default'
                    outputFrames = audiovideo.internal.IVideoReader.convertToDefault(inputFrames, inputFormat, vidReader, mltype);
                case 'native'
                    outputFrames = audiovideo.internal.IVideoReader.convertToNative(inputFrames, inputFormat, vidReader);
                otherwise
                    assert(false, 'Unexpected outputFormat %s', outputFormat);
            end
        end

        function outputFrames = convertToDefault(inputFrames, inputFormat, vidReader, mltype)
            if ~( strcmp(inputFormat, 'Indexed') || ...
                        strcmp(inputFormat, 'Grayscale') )
                % No conversion necessary, return the native data
                outputFrames = inputFrames;
                return;
            end

            colormap = vidReader.Colormap;
            
            % Return 'Indexed' data as RGB24 when asking for 
            % the 'Default' output.  This is done to preserve 
            % RGB24 compatibility for customers using versions of 
            % VideoReader prior to R2013a.
            outputFrames = zeros(size(inputFrames), mltype);

            if strcmp(inputFormat, 'Grayscale')
                for ii=1:size(inputFrames, 4)
                    % Indexed to Grayscale Image conversion (ind2gray) is part of IPT
                    % and not base-MATLAB.
                    tempFrame = ind2rgb( inputFrames(:,:,:,ii), colormap );
                    outputFrames(:,:,ii) = tempFrame(:, :, 1);
                end
            elseif strcmp(inputFormat, 'Indexed')
                outputFrames = repmat(outputFrames, [1, 1, 3, 1]);
                for ii=1:size(inputFrames, 4)
                    outputFrames(:,:,:,ii) = uint8(ind2rgb( inputFrames(:,:,:,ii), colormap));
                end
            end
        end  

        function outputFrames = convertToNative(inputFrames, inputFormat, vidReader)
            if ~ismember(inputFormat, {'Indexed', 'Grayscale'})
                % No conversion necessary, return the native data
                outputFrames = inputFrames;
                return;
            end

            colormap = vidReader.Colormap;
            
            % normalize the colormap
            colormap = double(colormap)/255;

            numFrames = size(inputFrames, 4);
            outputFrames = repmat(struct('cdata', [], 'colormap', []), 1, numFrames);
            for frameIndex = 1:numFrames
                outputFrames(frameIndex) = struct('cdata', inputFrames(:,:,:,frameIndex), 'colormap', colormap);
            end
        end

        function validateIndex(index)
        % This function does some basic checking on the indices provided -
        % ensures first value is less than the second value, and the number
        % of elements in index is less than 3. If any value in index is
        % Inf, then we validate it later.

            if isscalar(index)
                localIndex = [index index];
            else
                localIndex = index;
            end
            

            if numel(localIndex) > 2 || ( localIndex(1) > localIndex(2) )
                errorID = 'MATLAB:audiovideo:VideoReader:invalidFrameRange';
                audiovideo.internal.IVideoReader.throwError(errorID);
                return;
            end

            % If an index is specified as Inf, then the validation will be
            % performed later 
            if any( isinf(localIndex) )
                return;
            end
        end
        
        function throwError(errorID, varargin)
            % Use the suitable error function depending upon the target.
            if coder.target('MATLAB')
                error(message(errorID, varargin{:}));
            else
                coder.internal.error(errorID, varargin{:});
            end
        end
    end
    
    %------------------------------------------------------------------
    % Static helpers: Used by the sub-classes as well
    %------------------------------------------------------------------
    methods(Static, Access='protected')
        function type = computeFrameDatatype(vidFormat)
            switch vidFormat
                case {'Mono8 Signed', 'RGB24 Signed'}
                    type = 'int8';
                case {'Mono16', 'RGB48'}
                    type = 'uint16';
                case {'Mono16 Signed', 'RGB48 Signed'}
                    type = 'int16';
                otherwise
                    type = 'uint8';
            end
        end
        
        function numChannels = computeNumColorChannels(videoFormat)
            if contains(videoFormat, 'RGB')
                numChannels = 3;
            else
                numChannels = 1;
            end
        end
    end
end