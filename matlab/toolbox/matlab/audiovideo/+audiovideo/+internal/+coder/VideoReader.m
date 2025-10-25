%#codegen

classdef VideoReader < audiovideo.internal.IVideoReader
    % audiovideo.internal.coder.VideoReader Implementation for the codegen
    % version of VideoReader
    
    %   Copyright 2018 The MathWorks, Inc.
    
    properties(Access='private')
        % Stores a flag to track if the constructed object is valid or not.
        % This comes into play only during code generation. This will
        % always be TRUE in MATLAB
        IsValid = true;
        
        % Flag to determine whether the input file name is a compile time
        % constant.
        IsFileConst = false;
    end
       
    methods(Access='public')
        %------------------------------------------------------------------
        % Lifetime
        %------------------------------------------------------------------
        function obj = VideoReader(fileName, varargin)
            obj@audiovideo.internal.IVideoReader(fileName, varargin{:});
        end
        
        %------------------------------------------------------------------
        % Operations: See base-class
        %------------------------------------------------------------------
        
        %------------------------------------------------------------------
        % Overrides of built-ins
        %------------------------------------------------------------------
        function inspect(~)
            % This will fail during code generation.
            coder.internal.assert(false, 'MATLAB:audiovideo.VideoReader:coderInspectUnsupported');
        end
        
        function obj = saveobj(obj)
            % This will fail during code generation.
            coder.internal.assert(false, 'MATLAB:audiovideo:VideoReader:coderSaveUnsupported');
        end
    end
    
    %------------------------------------------------------------------
    % Implementation of Abstract methods
    %------------------------------------------------------------------
    methods(Access='protected', Sealed)
        function currTime = parseCreationArgs(obj, varargin)
            % A maximum of three name-value pairs are supported by
            % VideoReader
            narginchk(1, 7);

            % If the CurrentTime is not a name-value pair supplied, the
            % value returned is NaN
            currTime = NaN;
            
            % This condition will either fail at compile time or not at
            % all.
            coder.internal.assert( mod(nargin, 2) == 1, ...
                                   'MATLAB:audiovideo:VideoReader:coderInvalidNumArgs' );

            % Parse the name-value pairs. Only the standard name-value
            % pairs syntax i.e. 'Name1', 'Value1', 'Name2', 'Value2' is
            % supported. The set-style syntax is not supported in codegen.
            for cnt = 1:2:numel(varargin)
                % Validate that the name is actually a char and not a
                % cell-array. This is possible for the set-style syntax.
                % This condition will fail at compile time or not at all.
                coder.internal.assert( ~iscell(varargin{cnt}), ...
                            'MATLAB:audiovideo:VideoReader:coderSetStyleNotSupported' );
                
                validatestring(varargin{cnt}, {'CurrentTime', 'Tag', 'UserData'}, 'VideoReader');
                
                % The validation of the values for each name-value pair is
                % done in its setter.
                switch(varargin{cnt})
                    case 'CurrentTime'
                        currTime = varargin{cnt+1};
                    case 'Tag'
                        obj.Tag = varargin{cnt+1};
                    case 'UserData'
                        obj.UserData = varargin{cnt+1};
                    otherwise
                        coder.internal.error( 'MATLAB:audiovideo:VideoReader:UnsupportedNV', ...
                                              'CurrentTime', ...
                                              'Tag', ...
                                              'UserData' );
                        currTime = -1;
                        return;
                end
            end
        end
        
        function initReader(obj, fileName, currentTime)
            % Determine if the input filename is a compile-time constant.
            obj.IsFileConst = coder.internal.isConst(fileName);
            
            % Properly initialize the object on construction or load.            
            coder.extrinsic('ispc');
            coder.extrinsic('ismac');
            
            computeTimestampsOnCreation = coder.const(ispc) || coder.const(ismac);
            obj.VidReader = matlab.internal.VideoReader( fileName, ...
                                        'ComputeTimestampsOnCreation', ...
                                        computeTimestampsOnCreation ); 

            % If run-time checks are turned OFF, then the MIVR will be
            % constructed but the video file cannot be processed.
            % Check if the MIVR is valid and mark this object suitably.
            obj.IsValid = ~isnan(obj.VidReader.Height);
            
            postInit(obj, currentTime);
        end
        
        function createEmptyFrame(obj)
            % For MATLAB Coder, the empty frame should have the same type
            % as a valid frame.
            numChannels = audiovideo.internal.IVideoReader.computeNumColorChannels(obj.VideoFormat);
            sampleData = coder.nullcopy( zeros(obj.Height, obj.Width, numChannels, obj.MLType) );
            
            obj.EmptyFrame = struct( 'Data', sampleData, 'Timestamp', NaN );
            obj.EmptyOutput = zeros(0, 0, numChannels, obj.MLType);
        end
        
        % See audiovideo.internal.IVideoReader
        function cacheFrameTargetImpl(obj, timeInSecs)
            if ~obj.IsValid
                return;
            end
            
            % As we cannot catch any exceptions, reading ahead will throw
            % an error as soon as a corrupt frame is detected. 
            if isnan(timeInSecs)
                if ~hasFrame(obj.VidReader)
                    obj.StoredFrame = obj.EmptyFrame;
                    return;
                end
                obj.StoredFrame = readNextFrame(obj.VidReader);
            else
                obj.StoredFrame = readFrameAtPosition(obj.VidReader, timeInSecs);
            end
        end
        
        function outputformat = determineReadOutputFormat(~, ~)
            outputformat = 'default';
        end
        
        function checkIncompleteRead(~, actNumFramesRead, frameRangeToRead)
            expNum = frameRangeToRead(2) - frameRangeToRead(1) + 1;
            if actNumFramesRead < expNum
                
                coder.internal.warning( 'MATLAB:audiovideo:VideoReader:incompleteRead', ...
                    frameRangeToRead(1), frameRangeToRead(1)+actNumFramesRead-1 );
            end
        end
        function flag = hasFrameLite(obj)
            % In codegen, we do not cache any exceptions. Hence, an empty
            % stored frame marks the end of file.
            flag = ~isStoredFrameEmpty(obj);
        end
    end
    
    %------------------------------------------------------------------
    % Helpers: Over-riding base-class methods
    %------------------------------------------------------------------
    methods (Access='protected', Sealed)
        function cleanupOnError(obj)
            obj.IsValid = false;
        end
        
        function type = getMLType(obj)
            % All file types are supported in generated code if the file is
            % a compile time constant. Else, only files that contain data
            % that decodes to uint8 is supported.
            if obj.IsFileConst
                type = getMLType@audiovideo.internal.IVideoReader(obj);
            else
                type = 'uint8';
            end
        end
        
        function videoFrames = readFramesUntilEnd(obj, startIndex)
            if nargin == 1
                startIndex = 1;
            end
            videoFrames = readFramesUntilEnd@audiovideo.internal.IVideoReader(obj, startIndex);
            if isempty(videoFrames)
                checkIfIndexOutOfRange(obj, startIndex);
            end
            reset(obj);
        end
        
        function videoFrames = readFramesInIndexRange(obj, indexRange)
            videoFrames = readFramesInIndexRange@audiovideo.internal.IVideoReader(obj, indexRange);
            if isempty(videoFrames)
                % This check is deferred in order to avoid the penalty of
                % frame counting 
                checkIfIndexOutOfRange(obj, indexRange);
            end
        end
        
        function videoFrame = readSingleFrame(obj, index)
            videoFrame = readSingleFrame@audiovideo.internal.IVideoReader(obj, index);
            if isempty(videoFrame)
                % This check is deferred in order to avoid the penalty of
                % frame counting 
                checkIfIndexOutOfRange(obj, index);
            end
        end
        
        function videoFrame = readFrameAtIndex(obj, index)
            videoFrame = readFrameAtIndex@audiovideo.internal.IVideoReader(obj, index);
            if isempty(videoFrame)
                % This check is deferred in order to avoid the penalty of
                % frame counting 
                checkIfIndexOutOfRange(obj, index);
            end
        end
        
        function videoFrames = readFrameSequence(obj, indexRange)
            videoFrames = readFrameSequence@audiovideo.internal.IVideoReader(obj, indexRange);
            % Do something more
        end
    end
    
    methods (Static, Hidden)
        % Specify the properties of the class that will not be modified
        % after the first assignment. This is being done to ensure that the
        % dimensions are reported as constant when the input file name is a
        % compile time constant. Also, ensures that the datatype is
        % reported correctly.
        function p = matlabCodegenNontunableProperties(~)
            p = {'IsFileConst', 'MLTypeInternal'};
        end
    end

    %------------------------------------------------------------------
    % Helpers: Specific to this class
    %------------------------------------------------------------------
    methods (Access='private')
    end
    
    %------------------------------------------------------------------
    % Static Helpers
    %------------------------------------------------------------------
    methods(Static, Access='private') 
    end
end

