classdef OutputStream < matlabshared.asyncio.internal.Stream
% A stream that buffers outgoing data and asynchronously writes to a device.
%
%   If the device supports output, then isSupported() will return true and
%   data can be written to the stream.
%
%   See also matlabshared.asyncio.internal.InputStream and matlabshared.asyncio.internal.Channel.

% Authors: DTL
% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private',Dependent=true)
        % The number of items that can be written without blocking.
        % If the stream has no size limit, Inf is returned.
        SpaceAvailable;

        % The number of items remaining to be transferred to the device.
        DataToSend;
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = OutputStream(channelImpl, countDimension)
        % OUTPUTSTREAM Create a wrapper for a channel's output stream.

        % OBJ = OUTPUTSTREAM(CHANNELIMPL) creates a proxy that wraps the
        % actual output stream of CHANNELIMPL.
        %
        % Notes:
        % If the channel has no output stream, then isSupported will return
        % false and no other methods will succeed.
            assert(nargin == 2, 'The parent channel and count dimension were not specified');

            % Construct super class.
            obj@matlabshared.asyncio.internal.Stream(channelImpl, countDimension, 'OutputStream');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [countWritten, err] = write(obj, data, packetSize)
        %WRITE Write data to the output stream.
        %
        % COUNTWRITTEN = WRITE(OBJ, DATA, PACKETSIZE)
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
        %       '' - No error occurred.

            if ~isnumeric(data) && ~islogical(data) && ~ischar(data) &&...
                    ~isstruct(data)
                coder.internal.error('asyncio:Channel:coderException', 'AsyncIO Coder supports writing numeric, logical, char, or struct data');
            end

            % Initialize return values.
            countWritten = 0;
            err = '';

            % Initialize internal values.
            countDimension = obj.CountDimension;

            % Calculate the number of items we are trying to write.
            countToWrite = size(data, countDimension);

            % If packet size is specified...
            % Convert the N dimensional matrix into a cell array of data
            % packets. Break data up along the countDimension into packets
            % of equal size (specified by packetSize).
            if (nargin ==4)
                % Validate packetSize.
                if ~(isnumeric(packetSize) && isscalar(packetSize) &&...
                     packetSize > 0)
                    coder.internal.error('asyncio:OutputStream:invalidPacketSize');
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
                                                                                  countDimension, packetSizes);

            else
                % Try to write the entire block of data as one packet.
                %packetSize = countToWrite;
                packetsToWrite = {data};
            end

            coder.varsize('packetsToWrite');

            packetStartIndex = 1;

            % While we need to write more data.
            while countWritten < countToWrite

                % If there is no space...
                if obj.getSpaceAvailable() == 0

                    % Wait for any space to be available.
                    status = obj.wait(@(obj) obj.getSpaceAvailable() > 0);

                    % If no space was available, break.
                    if ~strcmpi(status, 'completed')
                        % Set error value.
                        err = status;

                        % Don't consider done an error.
                        if strcmpi(status, 'done')
                            err = '';
                        end
                        break;
                    end
                end

                % Write as many data packets as there is room for.
                %for ii=1:numel(packetsToWrite)
                %count = obj.writePackets(packetsToWrite{ii});
                %if count == 0
                %    break;
                %end
                %countWritten = countWritten + count;
                %end

                if isstruct(data)
                    coder.internal.error('asyncio:Channel:coderException', 'AsyncIO Coder does not yet support writing struct data');
                else
                    [count, packetEndIndex] = obj.writeTypedData(packetsToWrite, packetStartIndex);
                end

                countWritten = countWritten + count;
                packetStartIndex = packetEndIndex;
            end
        end

        function [countWritten, packetEndIndex] = writeTypedData(obj, packets, packetStartIndex)
        %WRITETYPEDDATA Write a cell array of data packets to the output stream.
        %
        % [COUNTWRITTEN, PACKETENDINDEX] = WRITETYPEDDATA(OBJ, PACKETS, PACKETSTARTINDEX)
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

            if ~iscell(packets)
                coder.internal.error('asyncio:OutputStream:invalidPackets');
            end

            % Write as many data packets as there is room for - one at a time.
            % We may want to write multiple buffers per ceval to minimize the
            % amount of locking/unlocking on the output queue. (see below
            % for our first failed attempt at this).
            countWritten = 0;
            packetEndIndex = packetStartIndex;
            for ii = packetStartIndex:numel(packets)


                packet = packets{ii}; % Must do for coder.rref.
                countWrittenThisIteration = matlabshared.asyncio.internal.coder.API.outputstreamWriteTypedData(...
                    obj.StreamImpl, packet);
                if countWrittenThisIteration == 0
                    break;
                end
                countWritten = countWritten + countWrittenThisIteration;
                packetEndIndex = packetEndIndex + 1;
            end

            % Coder can't handle packets being an unknown size during packetsToArgs. We may need
            % to try and write a fixed size number of packets.
            %             % Write as many data packets as there is room for.
            %             [numPackets, args] = matlabshared.asyncio.internal.coder.OutputStream.packetsToArgs(packets);
            %             countWritten = coder.internal.indexInt(0);
            %             success = int32(0);
            %             success = coder.ceval('coderOutputStreamWriteBasic', ...
            %                                   obj.StreamImpl, ...
            %                                   coder.wref(countWritten),...
            %                                   numPackets, args{:});
            %             errorIfFailed(obj, success);
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
                %warning(message('asyncio:OutputStream:timeoutInDrain'));
                coder.internal.error('asyncio:OutputStream:timeoutInDrain');
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
        %         function [numPackets, args] = packetsToArgs(packets)
        %         % Helper function to convert a cell array of data packets into a
        %         % cell array of name, class, length, and value.
        %
        %             if isempty(packets)
        %                 numPackets = coder.internal.indexInt(0);
        %                 args = {};
        %                 return;
        %             end
        %
        %             numPackets = coder.internal.indexInt(numel(packets));
        %             args = cell(1,4*numPackets); % name, class, length, value
        %             argIdx = 1;
        %
        %             coder.unroll();
        %             % numPackets needs to be const.
        %             % Write the packets out one at a time or as a group of packets
        %             % where the number of packets in the group is constant.
        %             for ii = 1:4:numel(args)
        %                 args{ii} = coder.internal.stringConst('data');
        %                 args{ii+1} = coder.internal.stringConst(class(packets{argIdx}));
        %                 args{ii+2} = coder.internal.indexInt(numel(packets{argIdx}));
        %                 args{ii+3} = packets{argIdx};
        %                 argIdx = argIdx+1;
        %             end
        %         end
    end
end

% LocalWords:  DTL CHANNELIMPL COUNTWRITTEN PACKETSIZE COUNTWRITTEN WRITETYPEDDATA PACKETENDINDEX PACKETSTARTINDEX
