classdef OutputStream < matlabshared.asyncio.internal.Stream
% A stream that buffers outgoing data and asynchronously writes to a device.
%
%   If the device supports output, then isSupported() will return true and
%   data can be written to the stream.
%
%   See also matlabshared.asyncio.internal.InputStream and matlabshared.asyncio.internal.Channel.

% Authors: DTL
% Copyright 2007-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private',Dependent=true)
        % The number of items that can be written without blocking.
        % If the stream has no size limit, Inf is returned.
        SpaceAvailable;

        % The number of items remaining to be transferred to the device.
        DataToSend;
    end

    events(NotifyAccess='public')
        % Device has read data from the output stream and space is available
        % to write. The data associated with this event is an
        % matlabshared.asyncio.internal.DataEventInfo where CurrentCount is the amount of space
        % available to write.
        % NOTE: This event is never fired when the Channel is created with
        % an output stream limit of 0.
        DataRead
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = OutputStream(channelImpl)
        % OUTPUTSTREAM Create a wrapper for a channel's output stream.

        % OBJ = OUTPUTSTREAM(CHANNELIMPL) creates a proxy that wraps the
        % actual output stream of CHANNELIMPL.
        %
        % Notes:
        % If the channel has no output stream, then isSupported will return
        % false and no other methods will succeed.
            assert(nargin == 1, 'The parent channel was not specified');

            % Construct super class.
            obj@matlabshared.asyncio.internal.Stream( channelImpl );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [countWritten, err] = write(obj, data, packetSize)
        %WRITE Write data to the output stream.
        %
        % [COUNTWRITTEN, ERR] = WRITE(OBJ, DATA, PACKETSIZE)
        % writes the N dimensional matrix of data to the output stream.
        % If the count of given data is greater than SpaceAvailable
        % then this method will block. If blocking is needed, write will
        % wait until the requested number of items are written or the
        % channel is closed or the device is done writing data or an
        % error occurs.
        %
        % Inputs:
        % DATA - An N-dimensional matrix of data.
        %
        % PACKETSIZE - Indicates the number of items to attempt to write
        %     to the device at one time. This parameter is optional, and
        %     if specified, causes the data to be broken up along the
        %     count dimension into a cell array of packets before writing
        %     to the device. If not specified, the entire matrix will be
        %     written to the output stream as one packet. This value is
        %     implementation specific and will often depend on the behavior
        %     of the device adaptor.
        %
        % Outputs:
        % COUNTWRITTEN - The actual number of items written. This will
        %     always be equal to the number of items in DATA unless the
        %     channel was closed or the end of the device's space was
        %     reached.
        %
        % ERR - A string that indicates if any error occurred while
        %     waiting for data to be written. Possible values are:
        %       'timeout' -   The timeout elapsed.
        %       'invalid' - The channel or stream was deleted.
        %       'Reentrancy Prohibited' - Reentrancy occurred.
        %       '' - No error occurred.

        % stateCleanup and err will be empty and no protection is provided if
        % 1. obj.ReentryProtector is default constructed (OR)
        % 2. obj.ReentryProtector is constructed without "write" as input
        %
        % If obj.ReentryProtector is constructed with "write" as input
        % AND
        % If write is not already running
        % stateCleanup will have an onCleanup function handle and err will 
        % be empty.
        % If write is already running
        % stateCleanup will be empty and err will be "Reentrancy Prohibited"
        % This err will be returned as part of write method's output.
            [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector, "write"); %#ok<ASGLU> onCleanup carrier.

            if ~isempty(err)
                countWritten = 0;
                return;
            end

            % Initialize return values.
            countWritten = 0;
            err = '';

            % Calculate the number of items we are trying to write.
            countToWrite = size(data, obj.CountDimension);

            % If packet size is specified...
            % Convert the N dimensional matrix into a cell array of data
            % packets. Break data up along the countDimension into packets
            % of equal size (specified by packetSize).
            if (nargin == 3)
                % Validate packetSize.
                if ~(isnumeric(packetSize) && isscalar(packetSize) &&...
                     packetSize > 0)
                    error(message('asyncio:OutputStream:invalidPacketSize'));
                end

                % Create an array of packet sizes for the countDimension.
                numPackets = floor(countToWrite/packetSize);
                lastPacketSize = rem(countToWrite, packetSize);
                if lastPacketSize > 0
                    numPackets = numPackets + 1;
                end
                packetSizes = packetSize * ones(1,numPackets);
                if lastPacketSize > 0
                    packetSizes(end) = lastPacketSize;
                end

                % Break data up along the countDimension.
                packetsToWrite = matlabshared.asyncio.internal.Stream.splitPacket(data, ...
                                                                                  obj.CountDimension, packetSizes);
            else
                % Try to write the entire block of data as one packet.
                packetSize = countToWrite;
                packetsToWrite = {data};
            end

            % While we need to write more data.
            while countWritten < countToWrite

                % Optimization: Don't call wait unless needed and use
                % underlying stream directly - 55% speedup.
                if obj.StreamImpl.getSpaceAvailable() == 0

                    % Wait for any space to be available.
                    status = obj.wait(@(obj) obj.getSpaceAvailable() > 0);

                    % If no space was available, break.
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

                % Write as many data packets as there is room for.
                count = obj.writePackets(packetsToWrite);

                % Pop off packets that were successfully written.
                packetsWritten = ceil(count/packetSize);
                packetsToWrite = packetsToWrite(packetsWritten+1:end);
                countWritten = countWritten + count;
            end
        end

        function countWritten = writePackets(obj, packets)
        %WRITEPACKETS Write a cell array of data packets to the output stream.
        %
        % COUNTWRITTEN = WRITEPACKETS(OBJ, PACKETS)
        % Writes as many data packets from the cell array as the output stream
        % has room for. This method does not block.
        %
        % Inputs:
        % PACKETS - A cell array of data packets.
        %
        % Outputs:
        % COUNTWRITTEN - The actual number of items written. This may be
        % less than the number of items in the data packets if there is not
        % enough room in the output stream.
            if iscell(packets)
                countWritten = obj.StreamImpl.write(packets);
                return;
            end

            % Write as many data packets as there is room for.
            error(message('asyncio:OutputStream:invalidPackets'));
        end

        function drain(obj)
        % DRAIN Wait until all the data drains from the output stream.
        %
        % DRAIN(OBJ) waits until all data in the output stream has been
        % transferred to the device; however, if the channel is closed, or
        % the device becomes done, or a timeout occurs, or an error occurs
        % while waiting, then the remaining data in the output stream is
        % discarded.
        %
        % NOTE: This method honors the Timeout property of the stream while
        % waiting for the data to be drained.

        % Wait for data to be written out.

            status = obj.wait(@(obj) obj.getDataAvailable() == 0);

            % If object become invalid, return immediately.
            if strcmpi(status, 'invalid')
                return;
            end

            % Warn if we timed out.
            if strcmpi(status, 'timeout')
                warning(message('asyncio:OutputStream:timeoutInDrain'));
            end

            %  Discard anything left in the stream in case of error or
            %  timeout.
            obj.flush();
        end
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Property Access Methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function count = get.SpaceAvailable(obj)
            count = obj.getSpaceAvailable();
        end

        function count = get.DataToSend(obj)
            count = obj.getDataAvailable();
        end
    end

    methods(Static)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.asyncio.internal.coder.OutputStream';
        end
    end

    methods(Static, Hidden)
        function lock()
            mlock;
        end
    end
end

% LocalWords:  DTL CHANNELIMPL COUNTWRITTEN PACKETSIZE WRITEPACKETS
