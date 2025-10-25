classdef Stream < handle
% An abstract class that implements functionality common to all streams.

% Authors: DTL
% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private')
        % The dimension of the stream's data that indicates the item count.
        CountDimension;
    end

    properties(GetAccess='public',SetAccess='public')
        % The timeout value, in seconds, used by all blocking calls that
        % are implemented using the wait method.
        Timeout = 10.0;
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = Stream(channelImpl, countDimension, className)
        % STREAM Create a wrapper for a channel's stream.

        % OBJ = STREAM(CHANNELIMPL, CLASSNAME) creates an object that wraps
        % the actual underlying C++ stream implementation.
        %
            assert(nargin == 3, 'asyncio:Stream:invalidArgumentCount',...
                   'Invalid number of arguments');

            % Create underlying implementation.
            if strcmp(className,'InputStream')
                obj.StreamImpl = matlabshared.asyncio.internal.coder.API.channelGetInputStream(channelImpl);
            elseif strcmp(className,'OutputStream')
                obj.StreamImpl = matlabshared.asyncio.internal.coder.API.channelGetOutputStream(channelImpl);
            end

            % Hold onto channel
            obj.ChannelImpl = channelImpl;

            % Must get the count dimension from the constructor so Coder
            % knows that it is a constant (rather than getting it at
            % runtime from the converter plugin).
            % See also: matlabCodegenNontunableProperties
            obj.CountDimension = countDimension;
        end

        function delete(obj)
        % DELETE Destroy the wrapper of the stream.

        % Call destroy. Destroy exists so clients can explicitly
        % destroy the Channel. This is a work-around for the lack of
        % support for explicit delete() in MATLAB Coder. See g1756065
            destroy(obj);
        end

        function destroy(~)
        % DESTROY Destroy the wrapper of the stream.

        % Nothing to do here. The underlying coder Channel destroys the
        % coder streams.
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Getters/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isSupported(obj)
        % ISSUPPORTED Return true if the device supports this stream.
        %
        % RESULT = ISSUPPORTED(OBJ) returns true if the device supports
        % this stream and returns false otherwise. If false, all other
        % methods of OBJ will result in an error.

            result = matlabshared.asyncio.internal.coder.API.streamIsSupported(obj.StreamImpl);
        end

        function result = isDeviceDone(obj)
        % ISDEVICEDONE Return true if the device is done.
        %
        % RESULT = ISDEVICEDONE(OBJ) returns true if the device is "done".
        % For input, done may indicate that the end of file has been
        % reached and no more data will be written to the stream. For
        % output, done may indicate there is no longer any space available
        % on the device.

            result = matlabshared.asyncio.internal.coder.API.streamIsDone(obj.StreamImpl);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function addFilter(obj, filterPluginPath, options)
        % ADDFILTER Add a filter to the given stream.
        %
        % ADDFILTER(OBJ, FILTERPLUGINPATH, OPTIONS) adds a filter to the
        % stream by loading the given filter plug-in and initializing it
        % with the given options. Filters can be used to modify the data
        % passing between the stream and the underlying device.
        %
        % Inputs:
        % FILTERPLUGINPATH - The full path and name of the filter plug-in.
        % The file extension of the plug-in should be omitted.
        %
        % OPTIONS - A structure containing information that needs to be
        % passed to the filter plug-in during initialization. This parameter
        % is optional and defaults to an empty structure.
        %
        % Notes:
        % - Filters can only be added when the stream is in the closed state.
        % - Filters will be opened when the parent Channel is opened.
        % - Filters will be closed when the parent Channel is closed.
        % - Filters will be opened, applied, and closed in the same order
        %   in which they were added to the stream.
        %
        % See also matlabshared.asyncio.internal.Channel.open, matlabshared.asyncio.internal.Channel.close
        %

        % If no options specified, provide a default.
            if nargin < 3
                options = [];
            end

            matlabshared.asyncio.internal.coder.API.streamAddFilter(obj.StreamImpl, filterPluginPath, options);
        end

        function tuneFilters(obj, options)
        %TUNEFILTERS tunes all the filters of a stream.
        %
        %   TUNEFILTERS(OBJ, OPTIONS) tunes all the filters of the given stream by
        %   sending the given options to all the filters.
        %
        % Inputs:
        %    OPTIONS is a structure containing information that will be passed
        %    to all filter plug-ins for the given stream.
        %
        % Notes:
        %    1) Filters can be tuned whether the stream is open or closed.
        %    2) Filters will be tuned in the order in which they were added to the stream.
        %    3) If any filter throws an error, the remaining filters will not be tuned. The error will appear in
        %       the MATLAB command window, and the Channel will remain in the same open/closed state.
        %
        % See also matlabshared.asyncio.internal.Stream.addFilter, matlabshared.asyncio.internal.Channel.open, matlabshared.asyncio.internal.Channel.close

        % If no options specified, provide a default.
            if nargin < 2
                options = [];
            end

            matlabshared.asyncio.internal.coder.API.streamTuneFilters(obj.StreamImpl, options);
        end

        function flush(obj)
        % FLUSH Flush all data in the stream.
        %
        % FLUSH(OBJ) immediately discards all data in the stream.

            matlabshared.asyncio.internal.coder.API.streamFlush(obj.StreamImpl);
        end

        function status = wait(obj, completedFcn, timeoutInSeconds)
        % WAIT Wait until the completion function returns true, or the
        % stream is "done", or the timeout elapses, or an error occurs.

        % Timeout value to use.
            if nargin < 3
                timeoutInSeconds = obj.Timeout;
            else
                % Verify what was provided.
                if ~isfloat(timeoutInSeconds) || isnan(timeoutInSeconds) || ...
                        timeoutInSeconds < 0
                    coder.internal.error('asyncio:Stream:invalidTimeout');
                end
            end

            % Initialize return value.
            status = '';

            % Initialize internal values.
            timeout = false;
            done = false;
            completed = completedFcn(obj);
            startTic = tic();
            % NOTE: Order is important. Completed has priority over
            % done and timeout.
            while ~completed && ~done && ~timeout

                et = toc(startTic);
                if et < 1.0
                    % Just check for errors and other "background" stuff.
                    pause(obj, 0.0);
                else
                    pause(obj, 0.005);
                end

                et = toc(startTic);
                timeout = (et > timeoutInSeconds);
                done = obj.isDeviceDone() || ~obj.isOpen();
                completed = completedFcn(obj);
            end

            % Set error string based on the loop exit condition.
            if completed
                status = 'completed';
            elseif done
                status = 'done';
            elseif timeout
                status = 'timeout';
            end
        end
    end

    methods(Access='protected')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Getters/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isOpen(obj)
        % ISOPEN Return true if the stream is open, false otherwise..

            result = matlabshared.asyncio.internal.coder.API.streamIsOpen(obj.StreamImpl);
        end

        function count = getSpaceAvailable(obj)
        % GETSPACEAVAILABLE Get the amount of space available in the stream.
        % If the stream has no size limit, Inf is returned.

            count = matlabshared.asyncio.internal.coder.API.streamGetSpaceAvailable(obj.StreamImpl);
        end

        function count = getDataAvailable(obj)
        % GETDATAAVAILABLE Get the amount of data available in the stream.

            count = matlabshared.asyncio.internal.coder.API.streamGetDataAvailable(obj.StreamImpl);
        end
    end

    methods(Access='private')
        function pause(obj, seconds) %#ok<INUSL>
        % PAUSE for the given number of seconds while also checking for
        % an asynchronous error and other "background" stuff.
        % If an asynchronous error is found, close the Channel and display
        % the error.

            pause(seconds);
            % This will pause and check for asynchronous errors.
            % Turn this on when we implement the MessageHandler.
            %matlabshared.asyncio.internal.coder.API.channelPause(obj.ChannelImpl, seconds);
        end
    end

    methods(Access='protected',Static=true)

        function packets = splitPacket(packet, countDimension, sizes)
        % SPLITPACKET Split a PACKET into a cell array of packets.
        %
        % PACKETS = SPLITPACKET(PACKET, COUNTDIMENSION, SIZES) splits a
        % single matrix into a cell array of matrices that have the
        % given sizes along the count dimension. The inverse of
        % PACKET = CAT(COUNTDIMENSION, PACKETS{:})
        %
        % Inputs:
        % PACKET - The N-dimensional matrix to split.
        % COUNTDIMENSION - The dimension of packet that indicates the count.
        %    From 1 to ndims(packet).
        % SIZES - A matrix that indicates the length of each packet.
        %    The elements of SIZES must sum to the length of the count
        %    dimension of packet.
        %
        % Outputs:
        % PACKETS - A cell array containing the resulting packets.
        %

        % Initialize output.
            packets = cell(1,length(sizes));

            start = 1;
            for ii=1:length(sizes)
                packets{ii} = matlabshared.asyncio.internal.Stream.extractFromPacket(packet, countDimension, start, start+sizes(ii)-1);
                start = start + sizes(ii);
            end
        end

        function result = extractFromPacket(packet, countDimension, startIndex, endIndex)
        % EXTRACTFROMPACKET Extract the given sub-array in the count dimension.
        %
        % RESULT = EXTRACTFROMPACKET(PACKET, COUNTDIMENSION, STARTINDEX, ENDINDEX) extracts a
        % sub-array from the given matrix along the count dimension.
        %
        % Inputs:
        % PACKET - The N-dimensional array to extract data from.
        % COUNTDIMENSION - The dimension of the array along which to extract.
        %    From 1 to ndims(packet).
        % STARTINDEX - The index of the first element to extract.
        % ENDINDEX - The index of the last element to extract.
        %
        % Outputs:
        % RESULT - The resulting sub-array.
        %

        % Optimization for vectors - 50% over 2-D case.
            if isvector(packet)
                result = packet(startIndex:endIndex);

                % Optimization for 2-D arrays - 300% speedup over N-D case.
            elseif ismatrix(packet)
                if countDimension == 1
                    result = packet(startIndex:endIndex,:);
                else
                    result = packet(:,startIndex:endIndex);
                end

                % For N-D arrays
            else
                % Create a cell array of indices for every dimension.
                dims = cell(1,ndims(packet));
                for ii=1:length(dims)
                    if ii == countDimension
                        dims{ii} = startIndex:endIndex;
                    else
                        dims{ii} = 1:size(packet,ii);
                    end
                end
                result = packet(dims{:});
            end
        end

    end

    methods(Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'CountDimension'};
        end
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Property Access Methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function set.Timeout(obj, timeValue)
            assert(isscalar(timeValue) && isfloat(timeValue) &&...
                   timeValue >= 0.0,...
                   'Stream:timeout:invalidTime',...
                   'TIMEVALUE must be a non-negative scalar double');
            obj.Timeout = timeValue;
        end
    end

    properties(GetAccess='protected',SetAccess='private')
        % Underlying C++ implementation.
        StreamImpl;
        ChannelImpl;
    end
end

% LocalWords:  DTL CHANNELIMPL ISDEVICEDONE FILTERPLUGINPATH TUNEFILTERS GETSPACEAVAILABLE
% LocalWords:  SPLITPACKET COUNTDIMENSION EXTRACTFROMPACKET STARTINDEX ENDINDEX TIMEVALUE
% LocalWords:  GETDATAAVAILABLE
