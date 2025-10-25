%#codegen

classdef TimeStampManager < handle
    %TIMESTAMPMANAGER Manage the generation and querying of time-stamps
    %from video files in C/C++ generated code.
    %Currently, C/C++ code generation does not support event handling.
    %Hence, even though time-stamps are read in asynchronously, they cannot
    %be brought into MATLAB in an event-driven manner in generated code.
    %This class manages reading of time-stamps from the files.
    
    %   Authors: Dinesh Iyer
    %   Copyright 2018-2021 The MathWorks, Inc.
    
    % NOTE: As this is not event driven, this implementation will be slower
    % than MATLAB. However, the performance penalty will be amortized over
    % multiple reads to the same file.
    properties(GetAccess='public', SetAccess='private', Dependent)
        % Row-vector containing the time-stamps corresponding to all the
        % frames in the video file.
        TimeStamps;
        
        % Total number of frames contained in the video file.
        NumFrames;
    end
    
    properties(GetAccess='public', SetAccess='private')
        % Flag to determine if all the time-stamps pertaining to the file
        % are available.
        IsAllTimeStampsRead = false;
    end
    
    properties(Access='private')
        % Vector of timestamps that is populated incrementally for video
        % files that require a time-stamp channel. This vector is
        % pre-allocated.
        InternalTimeStamps;
        
        % Indicates the number of entries of InternalTimeStamps property
        % that are sorted and hence valid for usage.
        NumValidTimeStamps = 0;
        
        % Total number of time-stamps contained in the InternalTimeStamps
        % property. This is less than the total size of the
        % InternalTimeStamps vector as we allocate extra to guard against
        % variable frame-rate videos.
        NumTotalTimeStamps = 0; 
    end
    
    properties(Access='private', Transient)
        TimeStampChannel
    end
    
    properties(Access='private', Constant)
        % For frame based reading, since the timestamps may not come in a
        % sorted order, we will read these many extra frames so that we can
        % ensure that the requested frame index is available 
        NumExtraSamplesToRead = matlab.internal.coder.TimeStampManager.configureNumExtraSamplesToRead();
        
        % Number of timestamps to read everytime data is pulled from the
        % timestamp channel. The actual number read can be less than this
        % if no more timestamps are available.
        MaxNumTimeStampsReadPerCall = matlab.internal.coder.TimeStampManager.configureMaxNumTimeStampsReadPerCall();
        
        % Number of extra elements to allocate in the time-stamp vector to
        % handle variable frame-rate videos. This is to guard against the
        % possibility that number of frames can be more than
        % frameRate*fileDuration.
        NumExtraSamplesInTimeStampVector = 500;
        
        NullChannelPluginName = 'videofilenullreaderplugin';
    end
    
    % Constructor
    methods
        function obj = TimeStampManager( fileDur, frameRate, tsPlugin, ...
                                         convPlugin, tsInitOptions, ...
                                         isComputeTSOnObjCreation )
            if contains(tsPlugin, obj.NullChannelPluginName)
                % This indicates that timestamps are not going to be
                % generated using a time-stamp channel but are going to be
                % computed in MATLAB                
                obj.generateTimeStamps(fileDur, frameRate, tsPlugin, ...
                                                convPlugin, tsInitOptions);
            else
                % Create the time stamp channel. This should succeed.
                obj.initTimeStampChannel( fileDur, frameRate, tsPlugin, ...
                                            convPlugin, tsInitOptions, ...
                                            isComputeTSOnObjCreation );
                                        
                % Read extra samples to guard against timestamps being in
                % decode order and not presentation order.
                numTimeStampsToRead = obj.MaxNumTimeStampsReadPerCall + ...
                                                obj.NumExtraSamplesToRead;                        
                                            
                % Pre-roll the time-stamp vector. This should be done only
                % if timestamp channel is requested to be opened for
                % reading.
                if obj.TimeStampChannel.isOpen()
                    obj.readTimeStamps(numTimeStampsToRead);
                end
            end
        end
        
        function delete(obj)
            close(obj.TimeStampChannel);
        end
    end
    
    % Getters
    methods
        function ts = get.TimeStamps(obj)
            % Wait until all time-stamps have been read
            while ~obj.IsAllTimeStampsRead
                obj.readTimeStamps(obj.MaxNumTimeStampsReadPerCall);
            end
            ts = obj.InternalTimeStamps(1:obj.NumValidTimeStamps);
        end
        
        function numFrames = get.NumFrames(obj)            
            numFrames = numel(obj.TimeStamps);
        end
    end
    
    methods(Access='public')
        function ts = getTimeStampAtIndex(obj, index)
            if index <= obj.NumValidTimeStamps
                ts = obj.InternalTimeStamps(index);
                % Read ahead more time-stamps to build up the time-stamp
                % vector
                obj.readTimeStamps(obj.MaxNumTimeStampsReadPerCall);
                return;
            end
            
            % Identify how many samples have to be read
            numSamplesToRead = index - obj.NumValidTimeStamps;
            
            % Read samples in multiples of MaxNumTimeStampsReadPerCall
            % instead of arbitrary values. This is just an implementation
            % choice.
            numSamplesToRead = ceil(numSamplesToRead/obj.MaxNumTimeStampsReadPerCall)* ...
                                obj.MaxNumTimeStampsReadPerCall;
                            
            if matlab.internal.coder.TimeStampManager.isLinux()
                % On Linux, as frame counting is done with decoding, we can
                % read the number of samples we need.
                obj.readTimeStamps(numSamplesToRead);
            else
                % Read ahead more time-stamps to build up the time-stamp
                % vector. Keep reading until we have read as many valid
                % timestamps as we want or we have read in all timestamps
                % or untill all timestamps have been read.
                while (index >= obj.NumValidTimeStamps) && ...
                        (obj.NumValidTimeStamps ~= obj.NumTotalTimeStamps) && ...
                        ~obj.IsAllTimeStampsRead
                    obj.readTimeStamps(numSamplesToRead);
                end
            end
            
            
            if index <= obj.NumValidTimeStamps
                ts = obj.InternalTimeStamps(index);
                % Read ahead more time-stamps to build up the time-stamp
                % vector. We are doing this to be consistent.
                obj.readTimeStamps(obj.MaxNumTimeStampsReadPerCall);
                return;
            end
            
            % Indicates that the time-stamp index is more than the total
            % number of time stamps available in the video.
            if coder.target('MATLAB')
                error(message('multimedia:videofile:invalidFrameIndex'));
            else
                if coder.internal.hasRuntimeErrors()
                    coder.internal.error('multimedia:videofile:invalidFrameIndex');
                else
                    ts = NaN;
                end
                return;
            end
        end
    end
    
    methods(Access='private')
        function generateTimeStamps(obj, fileDur, frameRate, tsPlugin, ...
                                                convPlugin, tsInitOptions)
            
            % Create a dummy AsyncIO Channel.
            % NOTE: Do not open this channel as it is not going to be used.
            createChannel(obj, tsPlugin, convPlugin, tsInitOptions);
            
            % Generate the timestamps vector
            obj.InternalTimeStamps = ( 0:1/frameRate:fileDur + eps(fileDur) )';
            obj.NumValidTimeStamps = numel(obj.InternalTimeStamps)-1;
            obj.NumTotalTimeStamps = numel(obj.InternalTimeStamps);
            
            % Indicate that all timestamps have been read. This will ensure
            % that the timestamp channel that is created will never ever be
            % used.
            obj.IsAllTimeStampsRead = true;
        end
        
        function initTimeStampChannel( obj, fileDur, frameRate, tsPlugin, ...
                                         convPlugin, tsInitOptions, ...
                                         isComputeTSOnObjCreation )
                                     
            % Pre-allocate the time-stamp vector. As videos can be VFR,
            % allocate more space than computed.
            obj.InternalTimeStamps = zeros( ceil(fileDur*frameRate) + ...
                                obj.NumExtraSamplesInTimeStampVector, 1 );
            
            createChannel(obj, tsPlugin, convPlugin, tsInitOptions);
            
            % Open the time-stamp channel only when we want to generate
            % time-stamps immediately.
            if isComputeTSOnObjCreation
                open(obj.TimeStampChannel);
            end
        end
        
        function createChannel(obj, tsPlugin, convPlugin, tsInitOptions)
            % Create the time-stamp channel. AsyncIO will error if this
            % fails.
            
            % Even though the TimeStampManager is used only for code
            % generation, the code below is being added so that it can be
            % tested using M unit-tests.
            if coder.target('MATLAB')
                obj.TimeStampChannel = matlabshared.asyncio.internal.Channel( tsPlugin, ...
                                                        convPlugin, ...
                                                        Options = tsInitOptions, ...
                                                        StreamLimits = [Inf Inf] );
            else
                obj.TimeStampChannel = matlabshared.asyncio.internal.Channel( tsPlugin,...
                                                        convPlugin,...
                                                        CountDimensions = [2 2],...
                                                        Options = tsInitOptions, ...
                                                        StreamLimits = [Inf Inf], ...
                                                        CoderExampleData = 0 ...
                                                       );
            end
        end
        
        function readTimeStamps(obj, numToRead)
            if obj.IsAllTimeStampsRead
                return;
            end
            
            if ~obj.TimeStampChannel.isOpen()
                obj.TimeStampChannel.open();
            end
            
            % Read the specified number of timestamps from the channel.
            % Even though the TimeStampManager is used only for code
            % generation, the code below is being added so that it can be
            % tested using M unit-tests.
            if coder.target('MATLAB')
                [tsv, actNumRead] = obj.TimeStampChannel.InputStream.read(numToRead);
            else
                [tsv, actNumRead] = obj.TimeStampChannel.InputStream.read(numToRead, 0);
            end
            
            % If there was an error reading the timestamps, a value of Inf
            % is returned. No further timestamps are sent by the plugin
            % after Inf.
            if actNumRead > 0
                if isinf(tsv(end))
                    tsv = tsv(1:end-1);
                    actNumRead = actNumRead - 1;
                end
            end
            
            startLoc = obj.NumTotalTimeStamps + 1;
            if actNumRead > 0
                % Assign these time-stamps to the suitable location in the
                % vector 
                endLoc = startLoc + actNumRead - 1;
                obj.InternalTimeStamps(startLoc:endLoc) = tsv;
                obj.NumTotalTimeStamps = endLoc;
            else
                % Indicates that there were no more timestamps available to
                % read from the video stream.
                endLoc = obj.NumTotalTimeStamps;
            end
            
            % Sort the time-stamps as they might be in decode order and not
            % presentation order. The entire vector need not be sorted
            % because the timestamps from 1:NumValidTimeStamps are assumed
            % to be valid to use and hence sorted.
            % On Linux, as we are counting upon decoding, we do not need to
            % sort the timestamps.
            startSortLoc = obj.NumValidTimeStamps + 1;
            if ~matlab.internal.coder.TimeStampManager.isLinux()
                obj.InternalTimeStamps(startSortLoc:endLoc) = ...
                            sort(obj.InternalTimeStamps(startSortLoc:endLoc));
            end
                        
            if actNumRead < numToRead
                % If number of samples read is lesser than requested, it
                % indicates that all timestamps must have been read.
                obj.NumValidTimeStamps = obj.NumTotalTimeStamps;
                obj.IsAllTimeStampsRead = true;
            else
                % This indicates that there could be more timestamps
                % present and so we ignore that last few timestamps read
                % in.
                numValidSamples = actNumRead - obj.NumExtraSamplesToRead;
                obj.NumValidTimeStamps = startSortLoc + numValidSamples - 1;
            end
        end
    end
    
    methods(Access='private', Static)
        function val = configureNumExtraSamplesToRead()
            % On Linux, as frame counting is done using decoding, no extra
            % timestamps have to be read to guard against unsorted
            % timestamps. On other platforms, choose a specific value.
            
            if matlab.internal.coder.TimeStampManager.isLinux()
                val = 0;
            else
                val = 50;
            end
            
        end
        
        function val = configureMaxNumTimeStampsReadPerCall()
            % On Linux, as frame counting is done using decoding, it is
            % sufficient to read only one timestamp everytime. Reading a
            % larger number can result in poorer performance.
            
            if matlab.internal.coder.TimeStampManager.isLinux()
                val = 1;
            else
                val = 1000;
            end
        end
        
        function tf = isLinux()
            coder.extrinsic('isunix');
            coder.extrinsic('ismac');
            isUnix = coder.const(isunix);
            isMac = coder.const(ismac);
            tf = coder.const(isUnix && ~isMac);
        end
    end
end
