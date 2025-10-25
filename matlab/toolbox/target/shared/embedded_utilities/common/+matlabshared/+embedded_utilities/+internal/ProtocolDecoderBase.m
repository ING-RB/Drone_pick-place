classdef ProtocolDecoderBase < matlab.System &  coder.ExternalDependency
    % Base class for decoder. Simulink block and MATLAB API respective
    % implementation should come on top of this

    %Copyright 2021-2024 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        Header double;
        TerminatorOption = '<none>';
        CustomTerminatorVal double;
        MaxVariableSizeFieldLength double;
        ChecksumSize double;
        ChecksumAlgorithm = 'XOR of bytes';
        CustomCSLogicFcnName = '';

        IsVariableSizeLastField (1, 1) logical = false;
        IsChecksumRequired (1, 1) logical = false;
        IsParseCSV (1, 1) logical = false;
        IsInputLengthAvailable (1, 1) logical = false;
    end

    properties(Abstract,Nontunable)
        FixedFieldDataTypes;
        FixedSizeFieldLength;
        CSVFieldLengthInBytes;
        FieldNames;
        IsLittleEndian;
    end

    properties (Hidden)
        TerminatorOptionSet =  matlab.system.StringSet(cellstr(["<none>", "CR ('\r')", ...
            "LF ('\n')", "CR/LF ('\r\n')", "NULL ('\0')", "Custom terminator"]));
        ChecksumAlgorithmSet = matlab.system.StringSet({'XOR of bytes','2''s complement of sum of bytes','Custom algorithm'});
    end

    properties(Access = protected,Nontunable)
        MinPayloadSize = uint16(0); % For fixed size packet, this value will be the 0;
        MaxPayloadSize = uint16(0); % For fixed size packet, this value will be the packet size
        ValidationFcnHandle % Function handle having checksum logic for custom checksum logic
    end

    properties(Access = protected,Nontunable)
        HeaderLength;
        TerminatorLength;
    end

    properties(Access = protected, Nontunable, Dependent)
        Terminator; % Value of the terminator
        FixedSizeFieldinBytes;
        DataTypeWidth; % Width for each datatype
    end

    properties(Access = protected)
        DataBuffer; % Data buffer to store partially parsed packets
        PrevOutCellArray = {}; % Cell array to store previous values
    end

    % Properties to readPacket in MATLAB
    properties(Access = protected)
        NumHeaderBytesReceived = uint8(0);
        NumTerminatorBytesReceived = uint8(0);
        DataBufferIndex = uint16(0);
        CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
    end

    methods
        function obj = ProtocolDecoderBase()
            coder.allowpcode('plain');
        end

        % Setters and getters are defined here
        function set.Header(obj, value)
            if ~isempty(value)
                validateattributes(value, {'numeric'}, ...
                    { '>=', 0, '<=', 255, 'real', 'nonnan','integer', 'row'}, ...
                    '', 'header');
                % Check if the header length is greater than uint8 range
                validateattributes(numel(value), {'numeric'}, ...
                    { '>', 0, '<=', 255, 'integer'}, ...
                    '', 'header length');
            end
            obj.Header = uint8(value);
        end

        function set.CustomTerminatorVal(obj, value)
            if ~isempty(value)
                if strcmpi(obj.TerminatorOption, 'Custom terminator')
                    validateattributes(value, {'numeric'}, ...
                        { '>=', 0, '<=', 255, 'real','nonnan','integer', 'row'}, ...
                        '', 'terminator');
                    % Check if the terminator length is greater than uint8
                    % range
                    validateattributes(numel(value), {'numeric'}, ...
                        { '>', 0, '<=', 255, 'integer'}, ...
                        '', 'terminator length');
                    obj.CustomTerminatorVal = uint8(value);
                end
            end
        end

        function set.MaxVariableSizeFieldLength(obj, value)
            if ~isempty(value)
                validateattributes(value, {'numeric'}, ...
                    { '>', 0, '<=', intmax('uint16'), 'real', 'nonnan', 'integer', 'scalar'}, ...
                    '', 'variable field length');
            end
            obj.MaxVariableSizeFieldLength = uint16(value);
        end

        function set.ChecksumSize(obj, value)
            if ~isempty(value)
                validateattributes(value, {'numeric'}, ...
                    { '>', 0, '<=', 255, 'real', 'nonnan', 'integer', 'scalar'}, ...
                    '', 'checksum size');
            end
            obj.ChecksumSize = uint8(value);
        end

        function value = get.Terminator(obj)
            if ~strcmpi(obj.TerminatorOption, '<none>')
                if ~strcmpi(obj.TerminatorOption, 'Custom terminator')
                    index = strfind(obj.TerminatorOption, '(');
                    terminatorVal = uint8(sprintf(obj.TerminatorOption(index+2 : end-2)));
                else
                    terminatorVal = obj.CustomTerminatorVal;
                end
            else
                terminatorVal = uint8(0);
            end
            value = uint8(terminatorVal);
        end

        function value = get.HeaderLength(obj)
            value = uint8(numel(obj.Header));
        end

        function value = get.TerminatorLength(obj)
            if ~strcmpi(obj.TerminatorOption, '<none>')
                value = uint8(numel(obj.Terminator));
            else
                value = uint8(0);
            end
        end

        function value = get.FixedSizeFieldinBytes(obj)
            if ~obj.IsParseCSV
                value = getFieldSizesInBytes(obj);
            else
                value = obj.CSVFieldLengthInBytes;
            end
        end

        function value = get.DataTypeWidth(obj)
            [~, value] = getFieldSizesInBytes(obj);
        end
    end

    methods (Access=protected)
        % System object functions
        function setupImpl(obj)
            if coder.target ('rtw')
                coder.cinclude('ProtocolDecoderUtilities.h');
            end
            % Databuffer size will be the packetSize
            packetSize = uint16(obj.HeaderLength) + uint16(obj.TerminatorLength)+ obj.MaxPayloadSize;
            % Buffer and variable to store previous packet
            obj.DataBuffer = uint8(zeros(1,packetSize));
            if obj.IsChecksumRequired
                if strcmpi(obj.ChecksumAlgorithm,'Custom algorithm')
                    % For custom checksum algorithms, create a function
                    % handle
                    obj.ValidationFcnHandle = coder.const(@str2func,obj.CustomCSLogicFcnName);
                end
            end
            % This is to initialize the cell array which contains previous
            % outputs if no new output is found
            resetPrevOutCellArray(obj);
        end

        function varargout = stepImpl(obj,inData,varargin)
            %% Validate input and initialize the variables
            if obj.IsInputLengthAvailable
                inDataLength = uint16(varargin{1});
                if numel(inData)>= inDataLength
                    inputValid = true;
                else
                    inputValid = false;
                end
            else
                inDataLength = uint16(numel(inData));
                inputValid = true;
            end
            if inputValid
                payloadLength= uint16(0);
                payload = uint8(zeros(1,obj.MaxPayloadSize));
                status = uint8(0);
                isValid = false;
                if obj.IsParseCSV || obj.IsVariableSizeLastField
                    isVariableSize = true;
                else
                    isVariableSize = false;
                end
                %% Read packed based on header, terminator and size specifications
                if coder.target('MATLAB')
                    [status,payload,payloadLength] = readPacket(obj,inData,inDataLength,isVariableSize);
                else
                    % To pass scalars by reference, the properties must be
                    % assigned to a temperory variable and then passed
                    header = obj.Header;
                    terminator = obj.Terminator;
                    % Decode the latest packet. If a complete packet is
                    % recieved, status = 1. payload will contain the packet
                    % and payloadLength indicates the valid packetsize
                    status = coder.ceval('readPacket',coder.ref(inData),inDataLength,...
                        coder.ref(header),obj.HeaderLength,...
                        coder.ref(terminator), obj.TerminatorLength,...
                        isVariableSize,obj.MinPayloadSize,obj.MaxPayloadSize,coder.ref(obj.DataBuffer),...
                        coder.wref(payload),coder.wref(payloadLength));
                end

                %% Validate packet using checksum
                if status ~= 0
                    payload(payloadLength+1:end) = uint8(0);
                    if obj.IsChecksumRequired
                        isValid = logical(validatePacket(obj,payload,payloadLength));
                        if ~isValid
                            % reset payload
                            payload(1:end) = uint8(0);
                            resetPrevOutCellArray(obj);
                            % Make the IsNew as true
                            numOut = getNumOutputsImpl(obj);
                            obj.PrevOutCellArray{numOut} = true;
                        else
                            % Remove checksum from the payload before
                            % further parsing
                            payload(payloadLength- uint16(getChecksumSize(obj))+1:payloadLength) = uint8(zeros(1,getChecksumSize(obj)));
                            payloadLength = payloadLength- uint16(getChecksumSize(obj));
                        end
                    else
                        isValid = true;
                    end
                end
                %% Parse packet based on size or commas
                if status ~= 0 && isValid
                    % Parse based on size
                    if ~obj.IsParseCSV
                        numOut = 0;
                        startIdx = uint16(1);
                        if ~isempty(obj.FixedSizeFieldLength)
                            for numOut=1:numel(obj.FixedSizeFieldLength)
                                % The below function parse the packet to
                                % get fixed size feilds from the payload starting from startIdx specified,
                                %  convert them into required output data
                                %  type.
                                varargout{numOut} = bytePacker(obj,payload,startIdx, numOut);
                                startIdx =  startIdx + obj.FixedSizeFieldinBytes(numOut);
                            end
                        end
                        % If the packet contain a variable size field,
                        % parse the variable size field and store its
                        % datalength as an output argument
                        if obj.IsVariableSizeLastField
                            numOut = numOut+1;
                            varargout{numOut} = payload(sum(obj.FixedSizeFieldinBytes)+1:sum(obj.FixedSizeFieldinBytes)+obj.MaxVariableSizeFieldLength);
                            numOut = numOut+1;
                            % Variable size field datalength
                            varargout{numOut} = payloadLength - sum(obj.FixedSizeFieldinBytes);
                        end
                    else
                        % Parsing based on CSV
                        numOut = 0;
                        startIdx = uint16(1);
                        if ~isempty(obj.CSVFieldLengthInBytes)
                            csvVariableLength = uint16(zeros(1,numel(obj.CSVFieldLengthInBytes)));
                            for numOut= 1:numel(obj.CSVFieldLengthInBytes)
                                if startIdx <= payloadLength
                                    % The below function looks for
                                    % occurance of comma and returns the
                                    % bytes between the startIdx and comma
                                    % in the payload from the the index
                                    % specified by startIdx. For the last
                                    % field end of packet is considered as
                                    % delimiter.endIdx is the index of the
                                    % packet at which the comma is found.
                                    % For next iteration look for comma
                                    % from this index
                                    [varargout{numOut},len,commaIdx] = parseCSV(obj,payload,payloadLength,startIdx,numOut);
                                    startIdx = commaIdx + uint16(1);
                                else
                                    % If required number of commas are not
                                    % found, return 0s
                                    varargout{numOut} = uint8(zeros(1,obj.CSVFieldLengthInBytes(numOut)));
                                    len = uint16(0);
                                end
                                csvVariableLength(numOut) = len;
                            end
                            % Output the length of parsed fields
                            numOut = numOut+1;
                            varargout{numOut} = csvVariableLength;
                        end
                    end
                    % Output IsValid
                    if obj.IsChecksumRequired
                        numOut = numOut+1;
                        varargout{numOut} = isValid;
                    end
                    % Output IsNew
                    numOut = numOut+1;
                    varargout{numOut} = true;
                    % Store the current output to PrevOutCellArray to
                    % output if next step doesnt have a new parsed
                    % output
                    obj.PrevOutCellArray = varargout;
                    % Make the IsNew output in PreviousOutput cell
                    % array as 1
                    obj.PrevOutCellArray{numOut} = false;
                else
                    varargout = obj.PrevOutCellArray;
                end
            else
                % If input is not valid
                varargout = obj.PrevOutCellArray;
            end
        end

        function releaseImpl(obj)
            if coder.target('MATLAB')
                % reset the states for reading the packet in MATLAB
                % workflow
                obj.NumHeaderBytesReceived = uint8(0);
                obj.NumTerminatorBytesReceived = uint8(0);
                obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                obj.DataBufferIndex = uint16(0);
            else
            end
        end

        function resetPrevOutCellArray(obj)
            % Initialize cell array to store previous values with zeros
            outputNum = getNumOutputsImpl(obj);
            obj.PrevOutCellArray = cell(1,outputNum);
            numOut = 0;
            if ~obj.IsParseCSV
                % Fixed feilds
                if ~isempty(obj.FixedSizeFieldLength)
                    for numOut=1:numel(obj.FixedFieldDataTypes)
                        obj.PrevOutCellArray{numOut} = cast(zeros(1,obj.FixedSizeFieldLength(numOut)), obj.FixedFieldDataTypes{numOut});
                    end
                end
                % Variable size feild
                if obj.IsVariableSizeLastField
                    numOut = numOut+1;
                    obj.PrevOutCellArray{numOut} = uint8(zeros(1,obj.MaxVariableSizeFieldLength));
                    % Variable size feild length
                    numOut = numOut+1;
                    obj.PrevOutCellArray{numOut} = uint16(0);
                end
            else
                if ~isempty(obj.CSVFieldLengthInBytes)
                    for numOut = 1:numel(obj.CSVFieldLengthInBytes)
                        obj.PrevOutCellArray{numOut} = uint8(zeros(1,obj.CSVFieldLengthInBytes(numOut)));
                    end
                    numOut = numOut+1;
                    obj.PrevOutCellArray{numOut}  = uint16(zeros(1,numel(obj.CSVFieldLengthInBytes)));
                end
            end
            if obj.IsChecksumRequired
                numOut = numOut+1;
                obj.PrevOutCellArray{numOut} = false;
            end
            numOut = numOut+1;
            obj.PrevOutCellArray{numOut} = false;
        end

        function [fixedSizeFieldinBytes, dataTypeWidth] = getFieldSizesInBytes(obj)
            % Dependinding on the data type and length of data required,
            % the function returns length in bytes along with with the data
            % type width used
            dataTypeWidth = uint8(zeros(1,numel(obj.FixedFieldDataTypes)));
            fixedSizeFieldinBytes = uint16(zeros(1,numel(obj.FixedFieldDataTypes)));
            for i=1:numel(obj.FixedFieldDataTypes)
                switch(obj.FixedFieldDataTypes{i})
                    case {'double','uint64','int64'}
                        dataTypeWidth(i) = uint8(8);
                    case {'single','int32','uint32'}
                        dataTypeWidth(i) = uint8(4);
                    case  {'int8','uint8','boolean'}
                        dataTypeWidth(i) = uint8(1);
                    case {'int16','uint16'}
                        dataTypeWidth(i) = uint8(2);
                    otherwise
                        dataTypeWidth(i) = uint8(1);
                end
                fixedSizeFieldinBytes(i) = obj.FixedSizeFieldLength(i) * uint16(dataTypeWidth(i));
            end
        end

        function [status,payload,payloadLength] = readPacket(obj,inData,inDataLength,isVariableSize)
            % MATLAB function to read based on header, terminator and size
            % requirement
            status = uint8(0);
            inputDataIndex = uint16(0);
            payload = uint8(zeros(1,obj.MaxPayloadSize));
            payloadLength = uint16(0);
            while(inputDataIndex < inDataLength)
                inputDataIndex = inputDataIndex + 1;
                presentChar = inData(inputDataIndex);
                switch obj.CurrentState
                    % Look for header
                    case matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader
                        if obj.Header(obj.NumHeaderBytesReceived + uint8(1)) == presentChar
                            % If complete header found
                            obj.NumHeaderBytesReceived = obj.NumHeaderBytesReceived + uint8(1);
                            if (obj.NumHeaderBytesReceived == obj.HeaderLength)
                                obj.NumHeaderBytesReceived = uint8(0);
                                obj.NumHeaderBytesReceived = uint8(0);
                                obj.DataBufferIndex = uint16(0);
                                if obj.MinPayloadSize == 0
                                    % For a  packets with no
                                    % fixed size feilds are known, store
                                    % data till terminator
                                    obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForTerminator;
                                else
                                    % For packets containing atleast one
                                    % fixed size feild
                                    obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForMinimumData;
                                end
                            end
                            % Check whether the present char is the first char of the pattern. For the case like
                            % header = 12, incoming byte stream = 112
                        elseif obj.Header(1) == presentChar
                            obj.NumHeaderBytesReceived = uint8(1);
                        else
                            obj.NumHeaderBytesReceived = uint8(0);
                        end
                        %  Wait for minimum amount of data.Variable size packet can have fixed size entries as well.
                        % For variable size packe, length of fixed size fields will be the minimum data length required
                        % For Fixed size packet, MinPayloadSize = MaxPayloadSize
                    case matlabshared.embedded_utilities.internal.DecodingStates.WaitForMinimumData
                        % Buffer till required packet size found
                        if (obj.DataBufferIndex < obj.MinPayloadSize)
                            obj.DataBufferIndex = obj.DataBufferIndex + uint16(1);
                            obj.DataBuffer(obj.DataBufferIndex) = presentChar;
                        end
                        % Required packet size found
                        if (obj.DataBufferIndex == obj.MinPayloadSize)
                            % If no terminator is required , copy the required bytes, reset the states and continue
                            if obj.TerminatorLength == 0
                                payloadLength = obj.DataBufferIndex;
                                payload(1:payloadLength) = obj.DataBuffer(1:payloadLength);
                                obj.NumTerminatorBytesReceived = 0;
                                obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                                obj.DataBufferIndex  = uint16(0);
                                status = uint8(1);
                            else
                                obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForTerminator;
                            end
                        end
                        % Look for terminator
                    case matlabshared.embedded_utilities.internal.DecodingStates.WaitForTerminator
                        % For fixed size packet, terminator bytes are expected right after the expected data
                        if isVariableSize == 0
                            if (obj.Terminator(obj.NumTerminatorBytesReceived+uint8(1)) == presentChar)
                                % Check if complete terminator is found
                                obj.NumTerminatorBytesReceived = obj.NumTerminatorBytesReceived+uint8(1);
                                if (obj.NumTerminatorBytesReceived == obj.TerminatorLength)
                                    payloadLength = obj.DataBufferIndex;
                                    payload(1:payloadLength) = obj.DataBuffer(1:payloadLength);
                                    obj.NumTerminatorBytesReceived = 0;
                                    obj.NumHeaderBytesReceived = 0;
                                    obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                                    obj.DataBufferIndex  = uint16(0);
                                    status = uint8(1);
                                end
                            else
                                % Invalid packet, reset the states
                                obj.NumTerminatorBytesReceived = 0;
                                obj.NumHeaderBytesReceived = 0;
                                obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                                obj.DataBufferIndex  = uint16(0);
                                inputDataIndex = inputDataIndex-1;
                            end
                        else
                            % For variable size packets
                            % Partial terminator bytes can be part of packet as well.
                            % Store the terminator bytes as well in the buffer
                            obj.DataBufferIndex = obj.DataBufferIndex + uint16(1);
                            obj.DataBuffer(obj.DataBufferIndex) = presentChar;
                            if (obj.Terminator(obj.NumTerminatorBytesReceived+uint8(1)) == presentChar)
                                % Check if complete terminator is found
                                obj.NumTerminatorBytesReceived = obj.NumTerminatorBytesReceived+uint8(1);
                                if (obj.NumTerminatorBytesReceived == obj.TerminatorLength)
                                    payloadLength = obj.DataBufferIndex - uint16(obj.TerminatorLength);
                                    payload(1:payloadLength) = obj.DataBuffer(1:payloadLength);
                                    obj.NumTerminatorBytesReceived = 0;
                                    obj.NumHeaderBytesReceived = 0;
                                    obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                                    obj.DataBufferIndex  = uint16(0);
                                    status = uint8(1);
                                end
                                % Check whether the present char is the first char of the pattern. For the case like
                                % terminator = 12, incoming byte stream = 112
                            elseif (obj.Terminator(1) == presentChar)
                                obj.NumTerminatorBytesReceived = uint8(1);
                            else
                                obj.NumTerminatorBytesReceived = uint8(0);
                            end
                            % If no terminator is found within the limit,reset the states
                            % For example, maxPacketSize = 2, termintor is *%
                            % Input stream is abc or ab*#
                            if ((obj.DataBufferIndex > obj.MaxPayloadSize) && (obj.NumTerminatorBytesReceived ~= obj.DataBufferIndex - obj.MaxPayloadSize))
                                obj.NumTerminatorBytesReceived = uint8(0);
                                obj.CurrentState = matlabshared.embedded_utilities.internal.DecodingStates.WaitForHeader;
                                obj.DataBufferIndex  = uint16(0);
                                inputDataIndex = inputDataIndex-1;
                            end
                        end
                end
            end
        end

        %% Validate packet using checksum
        function isValid = validatePacket(obj,payload,datalength)
            switch obj.ChecksumAlgorithm
                case 'XOR of bytes'
                    % Here CS Byte is expected to be 1 byte
                    csByte = payload(datalength);
                    packet = payload(1:datalength-1);
                    isValid = matlabshared.embedded_utilities.internal.validateCSXORofBytes(packet,csByte);
                case '2''s complement of sum of bytes'
                    % Here CS Byte is expected to be 1 byte
                    csByte = payload(datalength);
                    packet = payload(1:datalength-1);
                    isValid = matlabshared.embedded_utilities.internal.validateCS2sComplementSum(packet,csByte);
                case 'Custom algorithm'
                    csByte = payload(datalength-uint16(obj.ChecksumSize)+1:datalength);
                    packet = payload(1:datalength-uint16(obj.ChecksumSize));
                    isValid = obj.ValidationFcnHandle(packet,csByte);
                otherwise
                    isValid = false;
            end
        end

        function value = getChecksumSize(obj)
            if obj.IsChecksumRequired
                if strcmpi(obj.ChecksumAlgorithm,'Custom algorithm')
                    % Use the user specified checksum size
                    value = obj.ChecksumSize;
                else
                    % Other custom algorithms are byte based, so checksum
                    % size is expected to be 1 byte
                    value = uint8(1);
                end
            else
                value = uint8(0);
            end
        end
        %% Parsing logics
        function out = bytePacker(obj,inData,startIdx,numout)
            % bytePacker function, will cast uint8 bytes to the
            % specified data type and specified byte order. The function
            % starts looking for bytes in InData from startIdx. The
            % elements can be an array as well.
            inDataIdx = startIdx;
            idx = uint16(1);
            out = cast(zeros(1,obj.FixedSizeFieldLength(numout)),obj.FixedFieldDataTypes{numout});
            while inDataIdx<= startIdx+obj.FixedSizeFieldinBytes(numout)-1
                presentData = inData(inDataIdx: inDataIdx + uint16(obj.DataTypeWidth(numout)) -1);
                switch obj.FixedFieldDataTypes{numout}
                    case 'int8'
                        if presentData > 127
                            temp = int8(-1)*int8(uint8(255)-presentData + 1);
                        else
                            temp = int8(presentData);
                        end
                    case {'uint16','int16','uint32','int32','uint64','int64'}
                        temp = cast(0,obj.FixedFieldDataTypes{numout});
                        if obj.IsLittleEndian(numout)
                            for index = 1:obj.DataTypeWidth(numout)
                                temp = bitor(temp,bitshift(cast(presentData(index),obj.FixedFieldDataTypes{numout}),(8*(index-1))));
                            end
                        else
                            shiftIndex = obj.DataTypeWidth(numout);
                            for index = 1:obj.DataTypeWidth(numout)
                                temp = bitor(temp,bitshift(cast(presentData(index),obj.FixedFieldDataTypes{numout}),(8 *(shiftIndex-1))));
                                shiftIndex = shiftIndex-1;
                            end
                        end
                    case 'single'
                        % Convert the uint8 bytes to uint32 and then do a
                        % memcpy to single
                        out32Int = uint32(0);
                        if obj.IsLittleEndian(numout)
                            for index = 1:obj.DataTypeWidth(numout)
                                out32Int = bitor(out32Int,bitshift(cast(presentData(index),'uint32'),(8*(index-1))));
                            end
                        else
                            shiftIndex = obj.DataTypeWidth(numout);
                            for index = 1:obj.DataTypeWidth(numout)
                                out32Int = bitor(out32Int,bitshift(cast(presentData(index),'uint32'),(8 *(shiftIndex-1))));
                                shiftIndex = shiftIndex-1;
                            end
                        end
                        if coder.target('MATLAB')
                            temp = typecast(out32Int,'single');
                        else
                            temp = single(0);
                            len = uint8(0);
                            len = coder.ceval('sizeof',temp);
                            coder.ceval('memcpy',coder.wref(temp),coder.ref(out32Int),len);
                        end
                    case 'double'
                        % Convert the uint8 bytes to uint64 and then do a
                        % memcpy to double
                        out64Int = uint64(0);
                        if obj.IsLittleEndian(numout)
                            for index = 1:obj.DataTypeWidth(numout)
                                out64Int = bitor(out64Int,bitshift(cast(presentData(index),'uint64'),(8*(index-1))));
                            end
                        else
                            shiftIndex = obj.DataTypeWidth(numout);
                            for index = 1:obj.DataTypeWidth(numout)
                                out64Int = bitor(out64Int,bitshift(cast(presentData(index),'uint64'),(8 *(shiftIndex-1))));
                                shiftIndex = shiftIndex-1;
                            end
                        end
                        if coder.target('MATLAB')
                            temp = typecast(out64Int,'double');
                        else
                           temp = double(0);
                           len = uint8(0);
                           len = coder.ceval('sizeof',temp);
                           coder.ceval('memcpy',coder.wref(temp),coder.ref(out64Int),len);
                        end
                    otherwise
                        temp = uint8(presentData);
                end
                out(idx) = temp;
                idx = idx+1;
                inDataIdx = inDataIdx + uint16(obj.DataTypeWidth(numout));
            end
        end

        function [out,len,commaIdx] = parseCSV(obj,payload,payloadLength,startIdx,numOut)
            out = uint8(zeros(1,obj.CSVFieldLengthInBytes(numOut)));
            len = uint16(0);
            commaIdx = uint16(0);

            if coder.target('MATLAB')
                idx = startIdx;
                comma = uint8(44); % ASCII of ','
                commaFound = false;
                % Look for data between startIdx and commas in the payload and
                % store the length between startIdx and comma in len
                while idx <= payloadLength
                    if payload(idx) == comma
                        % For the cases with consecutive comma and no data in
                        % between (e.g GPS with no fix)
                        if idx == startIdx
                            out = uint8(zeros(1,obj.CSVFieldLengthInBytes(numOut)));
                        elseif ((idx-startIdx) <= obj.CSVFieldLengthInBytes(numOut))
                            out(1:idx-startIdx) = payload(startIdx:idx-1);
                        else
                            % If the datasize exceeds the maximum output
                            % length, truncuate the data and give it out
                            out(1:obj.CSVFieldLengthInBytes(numOut)) = payload(startIdx:startIdx + obj.CSVFieldLengthInBytes(numOut)-1);
                        end
                        len = idx-startIdx;
                        commaFound = true;
                        break;
                    end
                    idx = idx + uint16(1);
                end
                % If no comma found, use the end of packet as a delimiter
                if ~commaFound
                    % If there is no data after startIdx
                    if payloadLength == startIdx
                        out(1) = payload(startIdx);
                    elseif ((payloadLength-startIdx+1) <= obj.CSVFieldLengthInBytes(numOut))
                        out(1:payloadLength-startIdx+1) = payload(startIdx:payloadLength);
                    else
                        % If the datasize exceeds the maximum output
                        % length, truncuate the data and give it out
                        out(1:obj.CSVFieldLengthInBytes(numOut)) = payload(startIdx:startIdx+obj.CSVFieldLengthInBytes(numOut)-1);
                    end
                    len = payloadLength-startIdx + uint16(1);
                end
                commaIdx =  idx;
            else
                % MATLAB indexing starts from 1 and c indexing starts from
                % 0
                startIdx = startIdx - 1;
                coder.ceval('parseCSV',coder.ref(payload), payloadLength,...
                    startIdx,  obj.CSVFieldLengthInBytes(numOut),...
                    coder.ref(out), coder.wref(len),coder.wref(commaIdx));
                commaIdx = commaIdx + 1;
            end
        end

        %% Validate input and properties
        function validateInputsImpl(obj,inputData, inputLength) %
            % Validate that input data is of the type uint8
            validateattributes(inputData, {'uint8'}, {'vector',...
                'nonnan', 'finite', 'nonempty'}, 'Decoder', 'Input data');
            if obj.IsInputLengthAvailable
                validateattributes(inputLength, {'uint16','uint8'},...
                    {'scalar', 'nonnan', 'nonnegative', 'finite', 'nonempty'}, 'Decoder','Input data stream length');
            end
        end

        function validatePropertiesImpl(obj)
            % Validate header
            validateattributes(obj.Header, {'numeric'},{ '>=', 0, '<=', 255, 'real',...
                'nonempty','nonnan', 'integer'}, '','header');

            % If packet is variable, its mandatory to have a terminator
            if obj.IsVariableSizeLastField || obj.IsParseCSV
                if strcmpi(obj.TerminatorOption,'<none>')
                    error(message('embedded_utilities:general:noTerminator'));
                end
            end
            % Validate terminator
            if ~strcmpi(obj.TerminatorOption,'<none>') 
                if strcmpi(obj.TerminatorOption, 'Custom terminator')
                    validateattributes(obj.Terminator, {'numeric'}, ...
                        { '>=', 0, '<=', 255,'nonempty', 'real','nonnan','integer', 'row'}, ...
                        '', 'terminator');
                end
                if contains(char(obj.Terminator),char(obj.Header)) || contains(char(obj.Header),char(obj.Terminator))
                    error(message('embedded_utilities:general:uniqueHeaderTerminator'));
                end
            end

            % If custom checksum logic is selected, validate checksum size
            if obj.IsChecksumRequired && strcmpi(obj.ChecksumAlgorithm,'Custom algorithm')
                validateattributes(obj.ChecksumSize, {'numeric'}, ...
                    { '>', 0, '<=', 255, 'real','nonempty', 'nonnan', 'integer', 'scalar'}, ...
                    '', 'checksum size');
            end

            if obj.IsVariableSizeLastField
                validateattributes(obj.MaxVariableSizeFieldLength,...
                    {'numeric'}, { '>', 0, '<=', intmax('uint16'), 'real','nonempty',...
                    'nonnan', 'integer', 'scalar'}, '', 'variable size field length');
            end

            % Find the minimum and maximum payload size and validate if the total
            % packet size doesnt not exceed uint16 range.
            % Fo fixed size packet minPayloadSize =  maxPayloadSize
            if ~obj.IsParseCSV
                if ~obj.IsVariableSizeLastField
                    minPayloadSize = uint64(sum(obj.FixedSizeFieldinBytes)) + uint64(getChecksumSize(obj));
                    maxPayloadSize = uint64(sum(obj.FixedSizeFieldinBytes)) + uint64(getChecksumSize(obj));
                else
                    minPayloadSize = uint64(sum(obj.FixedSizeFieldinBytes)) + uint64(getChecksumSize(obj));
                    maxPayloadSize = uint64(sum(obj.FixedSizeFieldinBytes)) + uint64((obj.MaxVariableSizeFieldLength)) + uint64(getChecksumSize(obj));
                end
            else
                minPayloadSize = 0;
                % Max payload size here will be sum of all field lengths,
                % number of commas and checksum size if applicable
                maxPayloadSize = uint64(sum(obj.CSVFieldLengthInBytes)) + uint64(numel(obj.CSVFieldLengthInBytes)) + uint64(getChecksumSize(obj));
            end
            maxPacketSize = maxPayloadSize + uint64(obj.HeaderLength) + uint64(obj.TerminatorLength);
            if maxPacketSize > intmax('uint16')
                error(message('embedded_utilities:general:maxPacketSize',num2str(intmax('uint16'))));
            end
            obj.MinPayloadSize = uint16(minPayloadSize);
            obj.MaxPayloadSize = uint16(maxPayloadSize);
        end

        %% Propogation functions
        function num = getNumInputsImpl(obj)
            if obj.IsInputLengthAvailable
                num = 2;
            else
                num = 1;
            end
        end

        function num = getNumOutputsImpl(obj)
            if ~isempty(obj.FieldNames)
                num = numel(obj.FieldNames);
            else
                num = 0;
            end
            % is New output
            num = num + 1;
            if obj.IsParseCSV  || obj.IsVariableSizeLastField
                % datalength
                num = num+1;
            end
            if obj.IsChecksumRequired
                % Is Valid Output
                num = num+1;
            end
        end

        function [varargout] = isOutputFixedSizeImpl(obj)
            numOut = getNumOutputsImpl(obj);
            for i = 1:numOut
                varargout{i} = true;
            end
        end

        function varargout = isOutputComplexImpl(obj)
            numOut = getNumOutputsImpl(obj);
            for i = 1:numOut
                varargout{i} = false;
            end
        end

        function varargout = getOutputSizeImpl(obj)
            i = 0;
            if ~obj.IsParseCSV
                if ~isempty(obj.FixedSizeFieldLength)
                    for i=1:numel(obj.FixedSizeFieldLength)
                        varargout{i} = [1,obj.FixedSizeFieldLength(i)];
                    end
                end
                if obj.IsVariableSizeLastField
                    i = i+1;
                    varargout{i} = [1,obj.MaxVariableSizeFieldLength];
                    i = i+1;
                    varargout{i} = [1,1];
                end
            else
                if ~isempty(obj.CSVFieldLengthInBytes)
                    for i=1:numel(obj.CSVFieldLengthInBytes)
                        varargout{i} = [1,obj.CSVFieldLengthInBytes(i)];
                    end
                end
                i = i+1;
                varargout{i} = [1,numel(obj.CSVFieldLengthInBytes)];
            end
            % Is Valid Output
            if obj.IsChecksumRequired
                i = i+1;
                varargout{i} = [1,1];
            end
            % IsNew output
            i = i+1;
            varargout{i} = [1,1];
        end

        function varargout = getOutputDataTypeImpl(obj)
            i = 0;
            if obj.IsParseCSV
                if ~isempty(obj.CSVFieldLengthInBytes)
                    for i = 1:numel(obj.CSVFieldLengthInBytes)
                        varargout{i} = 'uint8';
                    end
                    i = i+1;
                    % Variable field data lengths
                    varargout{i} = 'uint16';
                end
            else
                if ~isempty(obj.FixedSizeFieldLength)
                    for i = 1:numel(obj.FixedSizeFieldLength)
                        varargout{i} = obj.FixedFieldDataTypes{i};
                    end
                end
                if obj.IsVariableSizeLastField
                    i = i+1;
                    % Variable size field
                    varargout{i} = 'uint8';
                    i = i+1;
                    % Variable size field data length
                    varargout{i} = 'uint16';
                end
            end
            if obj.IsChecksumRequired
                % Is Valid Output
                i = i+1;
                varargout{i} = 'logical';
            end
            i = i+1;
            % Is New output
            varargout{i} = 'logical';
        end
    end
    %% Build info
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'Protocol decoder';
        end

        function tf = isSupportedContext(~)
            tf = true;
        end

        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw') || context.isCodeGenTarget('sfun')
                % Update buildInfo
                rootDir = matlabshared.embedded_utilities.internal.getEmbeddedUtilitesRootDir;
                addIncludePaths(buildInfo, fullfile(rootDir, 'include'));
                addIncludeFiles(buildInfo,'ProtocolDecoderUtilities.h');
                addSourcePaths(buildInfo, fullfile(rootDir, 'src'));
                addSourceFiles(buildInfo,'ProtocolDecoderUtilities.c');
            end
        end
    end
end
