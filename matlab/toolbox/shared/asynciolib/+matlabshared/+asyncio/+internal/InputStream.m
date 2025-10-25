classdef InputStream < matlabshared.asyncio.internal.Stream
% A stream that asynchronously reads from a device and buffers incoming data.
%
%   If the device supports input, then isSupported() will return true and
%   data can be read from the stream.
%
%   See also matlabshared.asyncio.internal.OutputStream and matlabshared.asyncio.internal.Channel.

% Authors: DTL
% Copyright 2007-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private',Dependent=true)
        % The number of items that can be read without blocking.
        DataAvailable;
    end

    events(NotifyAccess='public')
        % Device has written data to the input stream and data is available
        % to read. The data associated with this event is an
        % matlabshared.asyncio.internal.DataEventInfo where CurrentCount is the amount of data
        % available to read.
        % NOTE: This event is never fired when the Channel is created with
        % an input stream limit of 0.
        DataWritten
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = InputStream(channelImpl)
        % INPUTSTREAM Create a wrapper for a channel's input stream.

        % OBJ = INPUTSTREAM(CHANNELIMPL) creates an object that wraps the
        % actual input stream of CHANNELIMPL.
        %
        % Notes:
        % If the channel has no input stream, then isSupported will return
        % false and no other methods will succeed.
            assert(nargin == 1, 'The parent channel was not specified');

            % Construct super class.
            obj@matlabshared.asyncio.internal.Stream( channelImpl );

            % Initialize an empty partial packet used by read.
            obj.clearPartialPacket();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isEndOfStream(obj)
        %ISENDOFSTREAM Test if the end of the stream is reached.
            result = obj.isDeviceDone() && (obj.DataAvailable() == 0);
        end

        function [data, countRead, err] = read(obj, countRequested)
        %READ Read data from the input stream.
        %
        % [DATA, COUNTREAD, ERR] = READ(OBJ, COUNTREQUESTED)
        % reads the requested number of items from the input stream. If the
        % count requested is less than DataAvailable then this method will
        % block. If blocking is needed, read will wait until the requested
        % number of items are read or the channel is closed or the device
        % is done reading data or an error occurs.
        %
        % Inputs:
        % COUNTREQUESTED - Indicates the number of items to read. This
        %     parameter is optional and defaults to all the data currently
        %     available on the input stream.
        %
        % Outputs:
        % DATA - An N-dimensional matrix of data. The dimension that
        %     indicates the count is specified by the CountDimension property.
        %     If no data was returned this will be an empty array.
        %
        % COUNTREAD - The actual number of items read. If there was no error,
        %     this value will be equal to the count requested unless the
        %     channel was closed or the device was done. If there was an
        %     error, this value will be zero.
        %
        % ERR - A string that indicates if any error occurred while
        %     waiting for data to arrive. Possible values are:
        %       'timeout' -   The timeout elapsed.
        %       'invalid' - The channel or stream was deleted.
        %       'Reentrancy Prohibited' - Reentrancy occurred.
        %       '' - No error occurred.

        % stateCleanup and err will be empty and no protection is provided if
        % 1. obj.ReentryProtector is default constructed (OR)
        % 2. obj.ReentryProtector is constructed without "read" as input
        %
        % If obj.ReentryProtector is constructed with "read" as input
        % AND
        % If read is not already running
        % stateCleanup will have an onCleanup function handle and err will 
        % be empty.
        % If read is already running
        % stateCleanup will be empty and err will be "Reentrancy Prohibited"
        % This err will be returned as part of read method's output.
            [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector, "read"); %#ok<ASGLU> onCleanup carrier.

            if ~isempty(err)
                data = [];
                countRead = 0;
                return;
            end

            % If countRequested not specified...
            if nargin < 2
                % Read what is available.
                countRequested = obj.DataAvailable;
                % Otherwise, validate it.
            elseif ~(isnumeric(countRequested) && isscalar(countRequested) && ...
                     countRequested >= 0)
                error(message('asyncio:InputStream:invalidCountRequested'));
            end

            % Initialize return values.
            err = '';

            % First get data left over from the previous read.
            [data, countRead] = obj.readPartialPacket(countRequested, obj.CountDimension);

            % If that fully satisfied our request, we're done.
            if countRead == countRequested
                return;
            end

            % Otherwise initialize the packets read so far.
            if countRead == 0
                packetsRead = {};
            else
                packetsRead = {data};
            end

            % While we need more data to satisfy the request.
            while countRead < countRequested

                % Optimization: Don't call wait unless needed and use
                % underlying stream directly - 15% speedup.
                if obj.StreamImpl.getDataAvailable() == 0

                    % Wait for any data to be available on the stream.
                    status = obj.wait(@(obj) obj.getDataAvailable() > 0);

                    % If no data was available, break.
                    if ~strcmpi(status, 'completed')
                        % Set error value.
                        err = status;

                        % If object became invalid, return immediately.
                        if strcmpi(status, 'invalid')
                            return;
                        end

                        % Don't consider done an error.
                        if strcmpi(status, 'done')
                            err = '';
                        end
                        break;
                    end
                end

                % Try to read what we need from the stream.
                countToRead = countRequested - countRead;

                % Get a cell array of data packets that satisfies
                % as much of our request that is available.
                [packets, count] = obj.readPackets(countToRead);

                % Accumulate the packets and the count.
                packetsRead = [packetsRead packets]; %#ok<AGROW>
                countRead = countRead + count;
            end

            % Now check if we got too much.
            if countRead > countRequested

                % Save the last packet as the partial packet.
                obj.setPartialPacket(packetsRead{end}, obj.CountDimension);

                % Determine how much of the last packet is needed.
                countNeeded = obj.PartialPacketCount - (countRead - countRequested);

                % Read what we need and use that as the last packet.
                packetsRead{end} = obj.readPartialPacket(countNeeded, obj.CountDimension);
            end

            % Concatenate cell array into a single matrix along the
            % count dimension.
            data = cat(obj.CountDimension, packetsRead{:});
            if ~isempty(data)
                countRead = size(data, obj.CountDimension);
            else
                countRead = 0;
            end

            % If there was an error, don't return any data,
            % but save it for any subsequent reads.
            if ~isempty(err)
                obj.setPartialPacket(data, obj.CountDimension);
                data = [];
                countRead = 0;
            end
        end

        function [packets, countRead] = readPackets(obj, countRequested)
        %READPACKETS Read a cell array of data packets from the input stream.
        %
        % [PACKETS, COUNTREAD] = READPACKETS(OBJ, COUNTREQUESTED)
        % reads a cell array of data packets from the input stream that
        % satisfies as much of our request as is available. This method does
        % not block.
        %
        % Inputs:
        % COUNTREQUESTED - Indicates the desired number of items to read.
        %
        % Outputs:
        % PACKETS - A 1xN cell array of data packets.
        %
        % COUNTREAD - The actual number of items read. This may be less than
        %     the number requested if enough data is not available in the
        %     input stream. It also may be more than the number requested
        %     if the count requested is not an even multiple of the packet
        %     size.
            [packets, countRead] = obj.StreamImpl.read(countRequested);
        end

        function flush(obj)
        % FLUSH Flush all data in the stream.
        %
        % FLUSH(OBJ) immediately discards all data in the stream.

        % Clear any partial packet left over from the last read.
            obj.clearPartialPacket();

            % Call superclass to discard anything in the stream.
            flush@matlabshared.asyncio.internal.Stream(obj);
        end
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Property Access Methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function count = get.DataAvailable(obj)
        % Start with any partial packet left over from the last read.
        % Add data available in the stream.
            count = obj.PartialPacketCount + obj.getDataAvailable();
        end
    end

    methods(Static)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.asyncio.internal.coder.InputStream';
        end
    end

    methods(Static, Hidden)
        function lock()
            mlock;
        end
    end

    methods(Access='private')

        function [dataRead, countRead] = readPartialPacket(obj, countRequested, countDimension)
        % If there is a partial packet, start with that.
            if obj.PartialPacketCount > 0
                % If the left over partial packet fully satisfies the read.
                if countRequested < obj.PartialPacketCount
                    dataRead = matlabshared.asyncio.internal.Stream.extractFromPacket(obj.PartialPacket, countDimension, obj.PartialPacketStart, ...
                                                                                      obj.PartialPacketStart+countRequested-1);
                    countRead = countRequested;
                    obj.PartialPacketStart = obj.PartialPacketStart + countRead;
                    obj.PartialPacketCount = obj.PartialPacketCount - countRead;
                else
                    % Use the entire remaining partial packet.
                    dataRead = matlabshared.asyncio.internal.Stream.extractFromPacket(obj.PartialPacket, countDimension, ...
                                                                                      obj.PartialPacketStart, obj.PartialPacketStart+obj.PartialPacketCount-1);
                    countRead = obj.PartialPacketCount;
                    % Clear partial packet.
                    obj.clearPartialPacket();
                end
            else
                dataRead = [];
                countRead = 0;
            end
        end

        function setPartialPacket(obj, data, countDimension)
            obj.PartialPacket = data;
            obj.PartialPacketStart = 1;
            obj.PartialPacketCount = size(data, countDimension);
        end

        function clearPartialPacket(obj)
            obj.PartialPacket = [];
            obj.PartialPacketStart = 0;
            obj.PartialPacketCount = 0;
        end
    end

    properties(GetAccess='private',SetAccess='private')
        % Holds any extra items from the last read.
        PartialPacket;
        PartialPacketStart;
        PartialPacketCount;
    end
end

% LocalWords:  DTL CHANNELIMPL ISENDOFSTREAM COUNTREAD COUNTREQUESTED READPACKETS
