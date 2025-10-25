classdef (Hidden) InputStream < matlabshared.asyncio.internal.Stream
% A stream that asynchronously reads from a device and buffers incoming data.
%
%   If the device supports input, then isSupported() will return true and
%   data can be read from the stream.
%
%   See also matlabshared.asyncio.internal.OutputStream and matlabshared.asyncio.internal.Channel.

% Copyright 2018-2023 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private',Dependent=true)
        % The number of items that can be read without blocking.
        DataAvailable;
    end
    
    properties (Access = 'private')
        %% Properties to handle Partial Buffer

        % PartialPacket is the Partial Buffer
        PartialPacket
        
        % PartialPacketStart holds the starting index for fetching data
        % from PartialPacket
        PartialPacketStart

        % PartialPacketCount holds the length of PartialPacket
        PartialPacketCount

        %% Property to Initialize the Partial Buffer

        % ExampleData receives the coderExampleData supplied to InputStream
        % constructor. It is used for initializing PartialPacket and to
        % validate coderExampleData supplied to Read method
        ExampleData
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = InputStream(channelImpl, countDimension, coderExampleData)
        % INPUTSTREAM Create a wrapper for a channel's input stream.

        % OBJ = INPUTSTREAM(CHANNELIMPL, COUNTDIMENSION, CODEREXAMPLEDATA) 
        % creates an object that wraps the actual input stream of CHANNELIMPL.
        %
        % Notes:
        % If the channel has no input stream, then isSupported will return
        % false and no other methods will succeed.

            % Construct super class.
            obj@matlabshared.asyncio.internal.Stream(channelImpl, countDimension, 'InputStream');
            % Validate coderExampleData at compile time if possible
            invalidExampleData = ~isnumeric(coderExampleData) && ... 
                        ~islogical(coderExampleData) && ...
                        ~ischar(coderExampleData) &&...
                        ~isstruct(coderExampleData);
            coder.internal.errorIf(invalidExampleData, 'asyncio:InputStream:coderInvalidExampleData');

            if isstruct(coderExampleData)
                % Make struct fields varsize in all dimensions
                obj.ExampleData = matlabshared.asyncio.internal.coder.InputStream.copyWithVarsize(coderExampleData);
            else
                % A varsize of non-struct exampleData is needed in order to
                % hold variable sizes of exampleData that can be passed in
                % read.
                coderExampleDataLocal = coderExampleData;
                coder.varsize('coderExampleDataLocal');
                obj.ExampleData = coderExampleDataLocal;
            end

            % Initialize the partial buffer
            obj.clearPartialPacket();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isEndOfStream(obj)
        %ISENDOFSTREAM Test if the end of the stream is reached.
            result = obj.isDeviceDone() && (obj.DataAvailable() == 0);
        end

        function [data, countRead, err] = read(obj, countRequested, varargin)
        %READ Read data from the input stream.
        %
        % [DATA, COUNTREAD] = READ(OBJ, COUNTREQUESTED, CODEREXAMPLEDATA)
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
        % CODEREXAMPLEDATA - Sample data for a single item along the Count 
        % Dimension. Must be numeric, logical, char, or struct.
        % For example:
        %    exampleData = zeros(1, numAudioChannels);
        % OR
        %    exampleData.Frame = zeros(height, width, numBands, 'uint8');
        %    exampleData.Timestamp = 0;
        %
        % Outputs:
        % DATA - An N-dimensional matrix of data. The dimension that
        %     indicates the count is specified by the CountDimensions.
        %     argument when constructing the Channel.
        %     If no data was returned this will be an empty version of the
        %     example data (e.g. 1x0 of uint8s).
        %
        % COUNTREAD - The actual number of items read. If there was no error,
        %     this value will be equal to at least the count requested unless
        %     the channel was closed or the device was done before all the data
        %     requested became available. If there was an error,
        %     this value will be zero. COUNTREAD can be more than 
        %     COUNTREQUESTED if the count requested does not end on a 
        %     packet boundary.
        %
        % ERR - A string that indicates if any error occurred while
        %     waiting for data to arrive. Possible values are:
        %       'timeout' - The timeout elapsed.
        %       '' - No error occurred.

            % Verify countRequested at compile time if possible
            invalidCountRequested = ~(isnumeric(countRequested) && ...
                                      isscalar(countRequested) && ...
                                      countRequested >= 0);
            coder.internal.errorIf(invalidCountRequested, 'asyncio:InputStream:invalidCountRequested');

            % Verify coderExampleData is not conflicting with obj.ExampleData
            if nargin > 2
                exampleData = varargin{1};
                % Check if the type is same
                coder.internal.errorIf(~isequal(class(obj.ExampleData), class(exampleData)), 'asyncio:InputStream:coderExampleDataTypeMismatch');
                % Check if the dimensions are same
                coder.internal.errorIf(any(coder.internal.ndims(obj.ExampleData) ~= coder.internal.ndims(exampleData)), 'asyncio:InputStream:coderExampleDataDimensionMismatch');
                % Check if the size is modified only when Partial Buffer is
                % empty
                sizeChangeWhenPartialBufferNonEmpty = any(size(obj.ExampleData) ~= size(exampleData)) && ~isempty(obj.PartialPacket);
                coder.internal.errorIf(sizeChangeWhenPartialBufferNonEmpty, 'asyncio:InputStream:coderExampleDataSizeChanged');
                if isstruct(obj.ExampleData)
                    fn = fieldnames(obj.ExampleData);
                    expectedFieldNames = fieldnames(exampleData);
                    % Check if the number of field names are same
                    coder.internal.errorIf(~isequal(length(fn), length(expectedFieldNames)), 'asyncio:InputStream:coderExampleDataStructFieldNumberMismatch');
                    for i = 1:length(fn)
                        % Check if the names of the fields are same
                        coder.internal.errorIf(~any(strcmp(fn{i}, expectedFieldNames)), 'asyncio:InputStream:coderExampleDataStructFieldNameMismatch');
                        % Check if the dimensions of every field is same
                        coder.internal.errorIf(coder.internal.ndims(obj.ExampleData.(fn{i})) ~= coder.internal.ndims(exampleData.(fn{i})), 'asyncio:InputStream:coderExampleDataDimensionMismatch');
                        % Check if size is changed only when Partial Buffer
                        % is empty
                        structSizeChangeWhenPartialBufferNonEmpty = any(size(obj.ExampleData.(fn{i})) ~= size(exampleData.(fn{i}))) && ~isempty(obj.PartialPacket);
                        coder.internal.errorIf(structSizeChangeWhenPartialBufferNonEmpty, 'asyncio:InputStream:coderExampleDataSizeChanged');
                    end
                end
                % Update the property to be current on the size changes
                obj.ExampleData = varargin{1};
            else
                % If coderExampleData is not provided, use the property
                exampleData = obj.ExampleData;
            end

            % Initialize return values.
            err = '';
            countRead = 0; %#ok<NASGU>

            % Initialize internal values.
            countDimension = obj.CountDimension;
            dataEmpty = matlabshared.asyncio.internal.coder.InputStream.makeEmptyData(exampleData, countDimension);
            dataRead = dataEmpty; %#ok<NASGU>
            coder.varsize('dataRead');
            
            % First get data left over from the previous read.
            [dataRead, countRead] = obj.readPartialPacket(countRequested, exampleData, countDimension);
            
            % If that fully satisfied our request, we're done.
            if countRead == countRequested
                data = matlabshared.asyncio.internal.coder.InputStream.extractFromVarSize(dataRead, obj.CountDimension, exampleData);
                return;
            end

            % While we need more data to satisfy the request.
            while countRead < countRequested

                if obj.getDataAvailable() == 0

                    % Wait for any data to be available on the stream.
                    status = obj.wait(@(obj) obj.getDataAvailable() > 0);

                    % If no data was available, break.
                    if ~strcmpi(status, 'completed')
                        % Set error value.
                        err = status;

                        % If object became invalid, return immediately.
                        if strcmpi(status, 'invalid')
                            data = dataEmpty;
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

                [packets, count] = obj.readPackets(countToRead, exampleData, countDimension);
                coder.varsize('packets');

                % Accumulate the packets and the count.
                for ii = 1:numel(packets)
                    dataRead = cat(countDimension, dataRead, packets{ii});
                end
                countRead = countRead + count;
            end
            
            if countRead > countRequested
                % Save excess data in the partial buffer.
                excessData = matlabshared.asyncio.internal.Stream.extractFromPacket(dataRead, countDimension, countRequested+1, countRead);
                obj.setPartialPacket(excessData, countDimension);
                % Retain only the expected data
                dataRead = matlabshared.asyncio.internal.Stream.extractFromPacket(dataRead, countDimension, 1, countRequested);
                countRead = countRequested;
            end

            % If there was an error (a timeout), return empty.
            % If there was no error, return the data read.
            if ~isempty(err)
                obj.setPartialPacket(dataRead, countDimension);
                data = dataEmpty;
                countRead = 0;
            else
                data = dataRead;
            end
        end

        function flush(obj)
        % FLUSH Flush all data in the stream.
        %
        % FLUSH(OBJ) immediately discards all data in the stream.

            % Clear Partial Buffer
            clearPartialPacket(obj);
            
            % Call superclass to discard anything in the stream.
            flush@matlabshared.asyncio.internal.Stream(obj);
        end
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Property Access Methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function count = get.DataAvailable(obj)
            % Add data available in the stream and Partial Buffer.
            count = obj.PartialPacketCount + obj.getDataAvailable();
        end
    end

    methods(Static)
        function dataEmpty = makeEmptyData(exampleData, countDimension)
        % Create an empty array that matches the dimensions of the
        % example data except with zero in the count dimension.
        % This will be suitable for the initial concatenation.
            dataEmpty = matlabshared.asyncio.internal.coder.InputStream.makeInitializedData(exampleData, countDimension, 0);
        end

        function dataInit = makeInitializedData(exampleData, countDimension, length)
        % Create an initialized array that matches the dimensions of the
        % example data except with length in the count dimension.
        % This will be suitable for the initialization.
            emptyTiling = cell(1,ndims(exampleData));
            for ii = 1:numel(emptyTiling)
                emptyTiling{ii} = 1;
            end
            emptyTiling{countDimension} = length;
            
            dataInit = repmat(exampleData,emptyTiling{:});
        end

        function s2 = copyWithVarsize(s)
        % COPYWITHVARSIZE returns a varsize version of struct s
            f = fieldnames(s);
            % The following utility allows making the loop generic. Without
            % this, coder would throw because in every loop, n could assume
            % a different size
            coder.unroll;
            for i = 1:numel(f)
                % For every field, makeVarSize only for vectors because
                % only vectors can grow and shrink.
                n = f{i};
                if isscalar(s.(n))
                    % For scalars varsizing is not required.
                    s2.(n) = s.(n);
                else
                    s2.(n) = matlabshared.asyncio.internal.coder.InputStream.makeVarsize(s.(n));                    
                end
            end
        end 
        
        function y = makeVarsize(x)
        % MAKEVARSIZE makes every dimension of x varsized to Inf
            y = x;
            % Find dimensions of x
            dims = coder.internal.ndims(x);
            % Make an array to indicate the upper limit of each dimension
            limit = Inf * ones(1,dims);
            % Make an array to indicate which dimension needs to be varsize
            dimsOfVarsize = ones(1,dims);
            % Make all dimensions unbounded
            coder.varsize('y', limit, dimsOfVarsize);
        end

        function out = extractFromVarSize(dataRead, countDimension, exampleData)
        % EXTRACTFROMVARSIZE extracts all the information from var sized 
        % variable dataRead to return a fixed size out
            
            
            % Handle both struct and non-struct types here
            if isstruct(dataRead)
                % Fetch the length of dataRead
                count = size(dataRead, countDimension);
                % Initialize return variable by replicating exampleData to the
                % size of dataRead which should make it fixed size
                out = matlabshared.asyncio.internal.coder.InputStream.makeInitializedData(exampleData, countDimension, count);
                for j = 1:count
                    % For every struct extract field names
                    str = dataRead(j);
                    f = fieldnames(str);
                    coder.unroll;
                    for i = 1:numel(f)
                        % For every field, convert to fixed size
                        % Get the field name
                        n = f{i};
                        % Get the field value
                        fieldArr = str.(n);

                        % Get the expected size of each element as a cell
                        % because Partial Constant Folding doesn't yet work
                        exampleField = exampleData.(n);
                        nd = coder.internal.ndims(exampleField);
                        sizeExData = cell(1,nd);
                        coder.unroll;
                        for k = 1:nd
                            sizeExData{k} = size(exampleField,k);
                        end
                        
                        % Get a range from var sized array so that fixed
                        % sized elements are returned
                        allElements = fieldArr(1:numel(exampleField));
                        % Rearrange the data in the expected size
                        out(j).(n) = reshape(allElements, sizeExData{:});
                    end
                end
            else
                % handling primitive types
                out = matlabshared.asyncio.internal.Stream.extractFromPacket(dataRead, countDimension, 1, size(dataRead, countDimension));
            end
        end
    end

    methods(Access='private')

        function [packets, countRead] = readPackets(obj, countRequested, exampleData, countDimension)
        %READPACKETS Read a cell array of data packets from the input stream.
        %
        % [PACKETS, COUNTREAD] = READPACKETS(OBJ, COUNTREQUESTED,  EXAMPLEDATA, COUNTDIMENSION)
        % reads a cell array of data packets from the input stream that
        % satisfies as much of our request as is available. This method does
        % not block.
        %
        % Inputs:
        % COUNTREQUESTED - Indicates the desired number of items to read.
        %
        % EXAMPLEDATA - Example data for a single "item" of data along the 
        % Count Dimension. Must be numeric, logical, or char.
        %
        % COUNTDIMENSION - The dimension when indicates the count of "items".
        %
        % Outputs:
        % PACKETS - A 1xN cell array of data packets.
        %
        % COUNTREAD - The actual number of items read. This may be less than
        %     the number requested if enough data is not available in the
        %     input stream. It also may be more than the number requested
        %     if the count requested is not an even multiple of the packet
        %     size.
        %

        % A Geck is captured to address the access conflict for this
        % function between Interpreted and codegen modes. g2551873. Post
        % this resolution, we need to decide whether exampleData needs to
        % stay in this function signature or not.

            if isstruct(exampleData)
                if countDimension < 1 || countDimension > 2
                    coder.internal.error('asyncio:Channel:coderException', 'When reading structure data, the count dimension must be 1 or 2');
                end
            end

            % Peek ahead and find out the number of buffers and the size of
            % each buffer that is needed to satisfy our request.
            [countToRead, bufferCounts, numBuffers] = ...
                matlabshared.asyncio.internal.coder.API.inputstreamPeek(obj.StreamImpl,...
                                                  countRequested);

            % Now create the space needed to hold the buffers that we are
            % about to read.
            packets = cell(1, numBuffers);
            coder.varsize('packets');

            defaultTiling = cell(1,2);
            for ii = 1:numel(defaultTiling)
                defaultTiling{ii} = 1;
            end

            % Create a 1 x numBuffers cell array where each element has
            % enough space to hold the data for that buffer.
            for bufferIndex = 1:numBuffers
                repmatTiling = defaultTiling;
                repmatTiling{countDimension} = bufferCounts(bufferIndex);
                packets{bufferIndex} = repmat(exampleData, repmatTiling{:});
            end

            % Read the buffers out of the queue.
            matlabshared.asyncio.internal.coder.API.inputstreamReadBuffers(...
                obj.StreamImpl,...
                countToRead,...
                numBuffers);

            % Fill each packet with data.
            % For each buffer...
            countRead = 0;
            for bufferIndex = 1:numBuffers

                packet = packets{bufferIndex};

                % For structures, we must read one item at a time because
                % we have to read one field at a time.
                if isstruct(obj.ExampleData)
                    for itemIndex = 1:bufferCounts(bufferIndex)

                        % Read a single structure item from the buffer.
                        packet(itemIndex) = obj.readStructItemData(...
                            bufferIndex,...
                            itemIndex,...
                            packet(itemIndex));
                    end

                    % For typed data, we can read all the items at once.
                else

                    itemIndex = 1; % Item index isn't used when reading typed data.
                    name = ''; % Field name isn't used when reading typed data.
                    
                    % Read data from the buffer.
                    packet = obj.readBufferData(...
                        bufferIndex,...
                        itemIndex,...
                        name,...
                        packet);
                end

                % Free the buffer.
                matlabshared.asyncio.internal.coder.API.inputstreamFreeBuffer(obj.StreamImpl, bufferIndex)

                packets{bufferIndex} = packet;
                countRead = countRead + bufferCounts(bufferIndex);
            end

            % TODO: Verify that the actual number that we read for all
            % packets equals what we expected.
            %countRead = countToRead;
        end

        function item = readStructItemData(obj, bufferIndex, itemIndex, item)

        %             % Would like to do this...read all fields at once for a given item.
        %             [numFields, args] = matlabshared.asyncio.internal.coder.InputStream.structToArgs(item);
        %             success = coder.ceval('coderInputStreamReadBufferData', ...
        %                               obj.StreamImpl, ...
        %                               bufferIndex, ...
        %                               itemIndex, ...
        %                               numFields, ...
        %                               coder.wref(args{:}));
        %             errorIfFailed(obj, success);

        % For each field in the structure...
            fields = fieldnames(item);
            numFields = coder.internal.indexInt(numel(fields));
            coder.unroll();
            for fieldIndex = 1:numFields

                % Get the value of that field.
                name = fields{fieldIndex};
                item.(name) = obj.readBufferData(...
                    bufferIndex,...
                    itemIndex,...
                    name,...
                    item.(name));
            end
        end

        function value = readBufferData(obj, bufferIndex, itemIndex, name, value)
        % Helper function to read a single field value of a structure from a buffer.
        % For typed data, itemIndex should be 1 and name should be empty

            value = matlabshared.asyncio.internal.coder.API.inputstreamReadBufferData(obj.StreamImpl,...
                                                              bufferIndex, itemIndex, name, value);
        end
        
        function [dataRead, countRead] = readPartialPacket(obj, countRequested, exampleData, countDimension)
        % READPARTIALPACKET reads from Partial Buffer
            ppc = obj.PartialPacketCount;
            if ppc > 0
                pps = obj.PartialPacketStart;
                if countRequested < ppc
                    % The left over partial packet fully satisfies the need
                    tempDataRead = matlabshared.asyncio.internal.Stream.extractFromPacket(obj.PartialPacket, countDimension, pps, pps+countRequested-1);
                    countRead = countRequested;
                    obj.PartialPacketStart = pps + countRead;
                    obj.PartialPacketCount = ppc - countRead;
                else
                    % Use the entire remaining partial packet.
                    tempDataRead = matlabshared.asyncio.internal.Stream.extractFromPacket(obj.PartialPacket, countDimension, pps, pps+ppc-1);
                    countRead = ppc;
                    obj.clearPartialPacket();
                end
                % Employ varsize to fix size conversion so that it gets applied only for those who read data more than 1 value. Only in here the contact with Partial Buffer happens. Hence the conversion is needed only here
                dataRead = matlabshared.asyncio.internal.coder.InputStream.extractFromVarSize(tempDataRead, obj.CountDimension, exampleData);
            else
                % Partial Buffer is empty. Return empty data.
                dataRead = matlabshared.asyncio.internal.coder.InputStream.makeEmptyData(exampleData, obj.CountDimension);
                countRead = 0;
            end
        end
        
        function setPartialPacket(obj, data, countDimension)
        % SETPARTIALPACKET assigns values to Partial Buffer and handles
        % associated properties
            obj.PartialPacket = data;
            obj.PartialPacketStart = 1;
            obj.PartialPacketCount = size(data, countDimension);
        end
        
        function clearPartialPacket(obj)
        % CLEARPARTIALPACKET clears Partial Buffer and associated
        % properties
            partialPacketInitializer = matlabshared.asyncio.internal.coder.InputStream.makeEmptyData(obj.ExampleData, obj.CountDimension);
            % obj.ExampleData indicates 1 sample data along the Count
            % Dimension. Partial buffer needs to hold an array of
            % such elements. Hence the following varsizing is needed.
            coder.varsize('partialPacketInitializer');
            obj.PartialPacket = partialPacketInitializer;
            obj.PartialPacketStart = 0;
            obj.PartialPacketCount = 0;
        end
        
    end
end

% LocalWords:  CHANNELIMPL COUNTDIMENSION CODEREXAMPLEDATA varsize ISENDOFSTREAM COUNTREAD
% LocalWords:  COUNTREQUESTED COPYWITHVARSIZE varsizing MAKEVARSIZE varsized EXTRACTFROMVARSIZE
% LocalWords:  READPACKETS EXAMPLEDATA READPARTIALPACKET SETPARTIALPACKET CLEARPARTIALPACKET
