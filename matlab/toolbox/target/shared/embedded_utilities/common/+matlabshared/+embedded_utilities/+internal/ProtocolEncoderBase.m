classdef ProtocolEncoderBase < matlab.System
    % Base class for encoder. Simulink block and MATLAB API respective
    % implementation should come on top of this

    %Copyright 2021 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        Header double;
        TerminatorOption = '<none>';
        CustomTerminatorVal double;
        ChecksumSize = 0;
        ChecksumAlgorithm = 'XOR of bytes';
        CustomCSLogicFcnName = '';

        IsChecksumRequired (1, 1) logical = false;
    end

    properties(Abstract,Nontunable)
        FixedFieldDataTypes;
        FixedSizeFieldLength;
        FieldNames;
        IsLittleEndian;
    end

    properties (Hidden)
        TerminatorOptionSet =  matlab.system.StringSet(cellstr(["<none>", "CR ('\r')", ...
            "LF ('\n')", "CR/LF ('\r\n')", "NULL ('\0')", "Custom terminator"]));
        ChecksumAlgorithmSet = matlab.system.StringSet({'XOR of bytes','2''s complement of sum of bytes','Custom algorithm'});
    end

    properties(Access = protected,Nontunable)
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

    methods
        function obj = ProtocolEncoderBase()
            coder.allowpcode('plain');
        end

        % Setters and getters are defined here
        function set.Header(obj, value)
            validateattributes(value, {'numeric'}, ...
                { '>=', 0, '<=', 255, 'real', 'nonnan','nonempty','integer', 'row'}, ...
                '', 'header');
            % Check if the header length is greater than uint8 range
            validateattributes(numel(value), {'numeric'}, ...
                { '>', 0, '<=', 255, 'integer'}, ...
                '', 'header length');
            obj.Header = uint8(value);
        end

        function set.CustomTerminatorVal(obj, value)
            if strcmpi(obj.TerminatorOption, 'Custom terminator')
                validateattributes(value, {'numeric'}, ...
                    { '>=', 0, '<=', 255, 'real','nonempty', 'nonnan','integer', 'row'}, ...
                    '', 'terminator');
                % Check if the terminator length is greater than uint8
                % range
                validateattributes(numel(value), {'numeric'}, ...
                    { '>', 0, '<=', 255, 'integer'}, ...
                    '', 'terminator length');
                obj.CustomTerminatorVal = uint8(value);
            end
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
            value = getFieldSizesInBytes(obj);
        end

        function value = get.DataTypeWidth(obj)
            [~, value] = getFieldSizesInBytes(obj);
        end
    end

    methods (Access=protected)
        % System object functions
        function setupImpl(obj)
            if obj.IsChecksumRequired
                if strcmpi(obj.ChecksumAlgorithm,'Custom algorithm')
                    % For custom checksum algorithms, create a function
                    % handle
                    obj.ValidationFcnHandle = coder.const(@str2func,obj.CustomCSLogicFcnName);
                end
            end
        end

        function packet = stepImpl(obj,varargin)
            packetLength = obj.HeaderLength + obj.TerminatorLength + getChecksumSize(obj) + sum(obj.FixedSizeFieldinBytes);
            packet = uint8(zeros(1,packetLength));
            % Add header into the packet
            packet(1:obj.HeaderLength) = obj.Header;
            idx = uint16(obj.HeaderLength) + 1;
            % Unpack each input into uint8 bytes as per the datatype and
            % byte order specified. Each Field can be array as well. The
            % byteUnPacker() takes array input and returns corresponding
            % byte arrays
            for i = 1:numel(obj.FixedSizeFieldLength)
                packet(idx:idx + obj.FixedSizeFieldinBytes(i)-1) = byteUnPacker(obj,varargin{i},i);
                idx = idx + obj.FixedSizeFieldinBytes(i);
            end
            % If CS byte is required, generate CS byte and append it to
            % packet
            if obj.IsChecksumRequired
                packet(idx:idx+uint16(getChecksumSize(obj))-1) = generateChecksum(obj,packet,idx-1);
                idx = idx+uint16(getChecksumSize(obj));
            end
            % If terminator is required, add terminator to the packet. If
            % no terminator is not required, next line will not have an
            % impact
            packet(idx:idx+uint16(obj.TerminatorLength)-1) = obj.Terminator;
        end

        function releaseImpl(~)
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
                % In MATLAB. integers can only be combined with same data
                % type integer, hence datatype width into uint16
                fixedSizeFieldinBytes(i) = obj.FixedSizeFieldLength(i) * uint16(dataTypeWidth(i));
            end
        end

        %% Validate packet using checksum
        function csBytes = generateChecksum(obj,packet,datalength)
            switch obj.ChecksumAlgorithm
                % exclude header from the packet before sending it to
                % validation logic
                case 'XOR of bytes'
                    csBytes = matlabshared.embedded_utilities.internal.generateCSXORofBytes(packet(uint16(obj.HeaderLength)+1:datalength));
                case '2''s complement of sum of bytes'
                    csBytes = matlabshared.embedded_utilities.internal.generateCS2sComplementSum(packet(uint16(obj.HeaderLength)+1:datalength));
                case 'Custom algorithm'
                    csBytes = uint8(obj.ValidationFcnHandle(packet(uint16(obj.HeaderLength)+1:datalength)));
                otherwise
                    csBytes = uint8(zeros(1,getChecksumSize(obj)));
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
        function out = byteUnPacker(obj,inData,numout)
            % bytePacker function, will cast specified input to
            % uint8 bytes stream according to the field type and specified
            % byte order.The  input elements can be an array as well.
            inDataIdx = uint16(1);
            out = uint8(zeros(1,obj.FixedSizeFieldinBytes(numout)));
            outIdx = uint16(1);
            while inDataIdx <= numel(inData)
                presentData = inData(inDataIdx);
                switch obj.FixedFieldDataTypes{numout}
                    case 'int8'
                        if presentData < 0
                            temp = 0xFF - uint8(-1*presentData) + 1;
                        else
                            temp = uint8(presentData);
                        end
                    case {'uint16','int16','uint32','int32','uint64','int64'}
                        temp = uint8(zeros(1,obj.DataTypeWidth(numout)));
                        andMask = cast(0xFF,obj.FixedFieldDataTypes{numout});
                        maxIndex = int8(obj.DataTypeWidth(numout));
                        if obj.IsLittleEndian(numout)
                            for index = 0:maxIndex-1
                                temp(index+1) = uint8(bitand(bitshift(presentData,-8*index), andMask));
                            end
                        else
                            arrayIdx = maxIndex;
                            for index = 0:maxIndex-1
                                temp(arrayIdx) = uint8(bitand(bitshift(presentData,-8*index), andMask));
                                arrayIdx = arrayIdx-1;
                            end
                        end
                    case 'single'
                        % Convert single in 32 bit and then convert to
                        % uint8 bytes
                        if coder.target('MATLAB')
                            out32Int = typecast(presentData,'uint32');
                        else
                            len = uint8(0);
                            len = coder.ceval('sizeof',presentData);
                            out32Int = uint32(0);
                            coder.ceval('memcpy',coder.wref(out32Int),coder.ref(presentData),len);
                        end
                        temp = uint8(zeros(1,obj.DataTypeWidth(numout)));
                        andMask = cast(0xFF,'uint32');
                        maxIndex = int8(obj.DataTypeWidth(numout));
                        if obj.IsLittleEndian(numout)
                            for index = 0:maxIndex-1
                                temp(index+1) = uint8(bitand(bitshift(out32Int,-8*index), andMask));
                            end
                        else
                            arrayIdx = maxIndex;
                            for index = 0:maxIndex-1
                                temp(arrayIdx) = uint8(bitand(bitshift(out32Int,-8*index), andMask));
                                arrayIdx = arrayIdx-1;
                            end
                        end
                    case 'double'
                        % Convert double in 64 bit and then convert to
                        % uint8 bytes
                        out64Int = uint64(0);
                        if coder.target('MATLAB')
                            out64Int = typecast(presentData,'uint64');
                        else
                            len = uint8(8);
                            len = coder.ceval('sizeof',presentData);
                            coder.ceval('memcpy',coder.ref(out64Int),coder.ref(presentData),len);
                        end
                        temp = uint8(zeros(1,obj.DataTypeWidth(numout)));
                        andMask = cast(0xFF,'uint64');
                        maxIndex = int8(obj.DataTypeWidth(numout));
                        if obj.IsLittleEndian(numout)
                            for index = 0:maxIndex-1
                                temp(index+1) = uint8(bitand(bitshift(out64Int,-8*index), andMask));
                            end
                        else
                            arrayIdx = maxIndex;
                            for index = 0:maxIndex-1
                                temp(arrayIdx) = uint8(bitand(bitshift(out64Int,-8*index), andMask));
                                arrayIdx = arrayIdx-1;
                            end
                        end
                    otherwise
                        temp = uint8(presentData);
                end
                out(outIdx:outIdx + uint16(obj.DataTypeWidth(numout))-1) = temp;
                outIdx = outIdx + uint16(obj.DataTypeWidth(numout));
                inDataIdx = inDataIdx + 1;
            end
        end

        %% Validate input and properties
        function validateInputsImpl(obj,varargin)
            % Check if input size and input data type is as specified in
            % the field table
            for i= 1:nargin-1
                % uint64 and int64 in System object is interpreted as embedded.fi object
                if (strcmpi(obj.FixedFieldDataTypes{i},'uint64') || strcmpi(obj.FixedFieldDataTypes{i},'int64')) && isa(varargin{i},'embedded.fi')
                    % In this check the wordlength and signedness of the
                    % input
                    if strcmpi(obj.FixedFieldDataTypes{i},'uint64')
                        if varargin{i}.WordLength ~= 64 || ~strcmpi(varargin{i}.Signedness,"Unsigned")
                            error(message('embedded_utilities:general:invalidDataType',obj.FieldNames{i},'uint64'));
                        end
                    end
                    if strcmpi(obj.FixedFieldDataTypes{i},'int64')
                        if varargin{i}.WordLength ~= 64 || ~strcmpi(varargin{i}.Signedness,"Signed")
                            error(message('embedded_utilities:general:invalidDataType',obj.FieldNames{i},'int64'));
                        end
                    end
                    % Validate the size of input
                    validateattributes(varargin{i},{'embedded.fi'},{'vector','nonnan', 'finite', 'nonempty','numel',obj.FixedSizeFieldLength(i)},'',obj.FieldNames{i});
                else
                   validateattributes(varargin{i},{obj.FixedFieldDataTypes{i}},...
                    {'vector','nonnan', 'finite', 'nonempty','numel',obj.FixedSizeFieldLength(i)},'',obj.FieldNames{i});
                end
            end
        end

        function validatePropertiesImpl(obj)
            % Validate header
            validateattributes(obj.Header, {'numeric'},{ '>=', 0, '<=', 255, 'real',...
                'nonempty','nonnan', 'integer'}, '','header');

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

            % Maximum packet size should not exceed the maximum of uint16
            % value
            packetSize = obj.HeaderLength + obj.TerminatorLength + getChecksumSize(obj) + sum(obj.FixedSizeFieldinBytes);
            if packetSize > intmax('uint16')
                error(message('embedded_utilities:general:maxPacketSize',num2str(intmax('uint16'))));
            end
        end

        %% Propogation functions
        function num = getNumInputsImpl(obj)
            num = numel(obj.FixedSizeFieldLength);
        end

        function num = getNumOutputsImpl(~)
            num = 1;
        end

        function out = isOutputFixedSizeImpl(~)
            out = true;
        end

        function out = isOutputComplexImpl(~)
            out = false;
        end

        function packet = getOutputSizeImpl(obj)
            packetSize = obj.HeaderLength + obj.TerminatorLength + getChecksumSize(obj) + sum(obj.FixedSizeFieldinBytes);
            packet = [1,packetSize];
        end

        function packet = getOutputDataTypeImpl(~)
            packet = 'uint8';
        end
    end
end