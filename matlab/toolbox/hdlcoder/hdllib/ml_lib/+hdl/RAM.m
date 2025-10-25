classdef (StrictDefaults)RAM < matlab.System
    % hdl.RAM Use RAM to read from and write to memory locations.
    %
    %   H = hdl.RAM creates a single port RAM System object. This object
    %   allows you to read from or write to a memory location in the
    %   RAM. The output data port corresponds to the read/write address
    %   passed in.
    %
    %   H = hdl.RAM('RAMType', 'Single port', 'WriteOutputValue',
    %   'Old data', 'RAMInitialValue', [0:31]) creates a single port RAM
    %   System object. This object allows you to read from or write to a
    %   memory location in the RAM. The RAM is initialized with the data [0:31].
    %   The output data port corresponds to the read/write address passed
    %   in. During a write operation, the old data at the write address is
    %   sent out as the output.
    %
    %   H = hdl.RAM('RAMType', 'Simple dual port') creates a simple
    %   dual port RAM System object. This object allows you to read from
    %   and write to different memory locations in the RAM. The output data
    %   port corresponds to the read address. If a read operation is
    %   performed at the same address as the write operation, old data at
    %   that address is read out as the output.
    %
    %   H = hdl.RAM('RAMType', 'Dual port', 'WriteOutputValue', 'New data')
    %   creates a dual port RAM System object. This object
    %   allows you to read from and write to different memory locations in
    %   the RAM. There are two output ports, a write output data port and a
    %   read output data port. The write output data port sends out the new
    %   data at the write address. The read output data port sends out the
    %   old data at the read address.
    %
    %   The type of input data to the step method determines RAM module
    %   instantiation:
    %       'scalar' - single RAM module instantiation
    %       'vector' - RAM banks instantiation. The number of RAM banks
    %       is inferred from the number of elements in the input vector.
    %       Either all inputs to the step method must have consistent
    %       sizes, or the first input (write data) must be a vector while all other
    %       inputs are scalars.
    %   The input can also be complex.
    %
    %   The size of the RAM is determined based on the size of the address.
    %   The size of each RAM bank, in the case of vector input, is
    %   determined based on the size of the address element in the address
    %   input vector. If the data type of the address is single or double,
    %   the size of the RAM is set to 2^16 locations; RAM size in general
    %   defaults to 16 bits, which covers most use cases. RAM size can
    %   significantly affect your simulations, and if you don't need 32
    %   bits, always specify the address bus by the correct fi-type, up to
    %   32 bits.
    %
    %   The output data is delayed by one step.
    %
    %   Step method syntax:
    %
    %   For a Single port RAM:
    %       DATAOUT = step(H, WRITEDATA, ...
    %                         READWRITEADDRESS, ...
    %                         WRITEENABLE)
    %   allows you to read the value in memory location READWRITEADDRESS
    %   when WRITEENABLE is false, or write the value WRITEDATA into
    %   the memory location READWRITEADDRESS when WRITEENABLE is
    %   true. DATAOUT is the new or old data at the READWRITEADDRESS
    %   when WRITEENABLE is true, or the data at READWRITEADDRESS
    %   when WRITEENABLE is false.
    %
    %   For a Simple dual port RAM:
    %       READDATAOUT = step(H, WRITEDATA,
    %                             WRITEADDRESS, ...
    %                             WRITEENABLE, ...
    %                             READADDRESS)
    %   allows you to write the value WRITEDATA into memory location
    %   WRITEADDRESS when WRITEENABLE is true. READDATAOUT is the
    %   old data at the address location READADDRESS.
    %
    %   For a Dual port RAM:
    %       [WRITEDATAOUT, READDATAOUT] = step(H, WRITEDATA, ...
    %                                             WRITEADDRESS, ...
    %                                             WRITEENABLE, ...
    %                                             READADDRESS)
    %   allows you to write the value WRITEDATA into the memory location
    %   WRITEADDRESS when WRITEENABLE is true. WRITEDATAOUT is the
    %   new or old data at memory location WRITEADDRESS. READDATAOUT
    %   is the old data at the address location READADDRESS.
    %
    %   System objects may be called directly like a function instead of
    %   using the step method. For example, y = step(obj, x) and y = obj(x)
    %   are equivalent.
    %
    %
    %   hdl.RAM Input Requirements:
    %
    %   WRITEDATA must be scalar, can be double, single, integer, or
    %   a fixed-point (fi) object, and can be real or complex.
    %
    %   WRITEENABLE must be a scalar value.
    %
    %   WRITEADDRESS and READADDRESS must be scalar, real and unsigned, and
    %   can be double, single, integer, or a fixed-point (fi) object.
    %
    %
    %   hdl.RAM methods:
    %
    %   step     - Read from or write input value to a memory location (see
    %              above)
    %   release  - Allow property value and input characteristics
    %              changes
    %   clone    - Create hdl.RAM object with same property values
    %   isLocked - Locked status (logical)
    %
    %
    %   hdl.RAM properties:
    %
    %   RAMType          - Specify the type of RAM to be created
    %                      'Single port'       (default)
    %                                          creates a single port RAM,
    %                                          with 3 inputs, Write Data,
    %                                          Write address, Write enable
    %                                          and 1 output, Read/Write
    %                                          Data
    %                      'Simple dual port'  creates a simple dual port
    %                                          RAM, with 4 inputs,
    %                                          Write Data,
    %                                          Write address,
    %                                          Write enable, Read address,
    %                                          and 1 output, Read Data
    %                      'Dual port'         creates a dual port RAM,
    %                                          with 4 inputs, Write Data,
    %                                          Read/Write address,
    %                                          Write enable, Read address,
    %                                          and 2 outputs, Write Data,
    %                                          Read Data
    %                      'True dual port'    creates a true dual port RAM,
    %                                          with 6 inputs, Write Data a,
    %                                          Read/Write address a,
    %                                          Write enable a, Write data b,
    %                                          Read/Write address b,
    %                                          write enable b, and 2
    %                                          outputs, Write Data a
    %                                          Write Data b
    %                      'Simple tri port'   creates a simple tri port
    %                                          RAM, with 5 inputs,
    %                                          Write Data,
    %                                          Write address,
    %                                          Write enable, Read address a,
    %                                          Read address b,
    %                                          and 2 outputs, Read Data a,
    %                                          Read Data b
    %   WriteOutputValue - Specify the behavior for the Write output port
    %                      for the Single port and Dual port RAMs
    %                      'New data' (default)  sends out new data at the
    %                                            address to the output
    %                      'Old data'            sends out old data at the
    %                                            address to the output
    %   RAMInitialValue  - Supply initial values for the RAM
    %                      0 (default) initializes every location to 0
    %                      A scalar initial value will initialize each
    %                      RAM location to the value. A one dimensional
    %                      array of values with the same number of
    %                      elements as the RAM will initialize the RAM
    %                      with the contents of the array.
    %   ModelRAMDelay    - Specify whether the RAM should be modeled with
    %                      1 cycle of delay
    %                      true (default)      Input data is delayed by
    %                                          1 cycle before it can be
    %                                          read at the output
    %                      false               Input data can be read
    %                                          and output immediately
    %                                          (direct feedthrough), but
    %                                          1 cycle of latency is added
    %                                          during HDL code generation
    %   VectorAccess     - Specify the behavior when a vector input is
    %                      given to the RAM
    %                      'Parallel' (default)  creates parallel banks
    %                                            of RAM
    %                      'Serial'              instantiates one RAM and
    %                                            serially accesses it
    %                                            starting with the first
    %                                            index of the vector inputs
    %
    %   % Example:
    %   % Write to a Single port RAM and read the newly written value out
    %   % Output data is delayed one step with respect to input data
    %   hRAM = hdl.RAM('RAMType', 'Single port', ...
    %                 'WriteOutputValue', 'New data');
    %
    %   % Pre-allocate memory
    %   dataLength    = 100;
    %   [dataIn, dataOut] = deal(zeros(1,dataLength));
    %   for ii = 1:dataLength
    %     dataIn(ii)  = randi([0 63],1,1,'uint8');
    %     addressIn   = uint8(ii-1);
    %     writeEnable = true;
    %     dataOut(ii) = hRAM(dataIn(ii), addressIn, writeEnable);
    %   end
    %

    %   Copyright 2011-2025 The MathWorks, Inc.

    %#codegen
    %#ok<*EMCLS>

    properties (Nontunable)
        % RAMType Specify the type of RAM
        %   Specify the RAM type to be one of 'Single port' |
        %   'Simple dual port' | 'Dual port' | 'True dual port' |
        %   'Simple tri port'
        %   The default is 'Single port'
        RAMType = 'Single port';
        % AsyncRead Enable asynchronous reads
        AsyncRead (1,1) logical = false;
        % WriteOutputValue Specify the output data for a write operation
        %   Specify WriteOutputValue to be one of 'New data' | 'Old data'
        %   When the WriteOutputValue is set to 'New data', during a write
        %   operation, the new data sent in to be written appears at the
        %   write output port.
        %   When the WriteOutputValue is set to 'Old data', during a write
        %   operation, the old data at the write address appears at the
        %   write output port.
        %   This property applies when you set the RAMType to 'Single port'
        %   or 'Dual port'.
        %   The default is 'New data'.
        WriteOutputValue = 'New data';
        % RAMInitialValue Specify the RAM initial value
        RAMInitialValue = 0;
        % ModelRAMDelay Model RAM with cycle of delay
        ModelRAMDelay (1,1) logical = true;
        % VectorAccess Specify vector input access as [{'Parallel'}|'Serial']
        VectorAccess = 'Parallel';
        % Deprecated hidden properties marked inactive
        allowBusInputs (1,1) logical = false;
        WritesHaveOutput (1,1) logical = true;
        NumReads = 0;
        NumWrites {mustBePositive} = 1;
    end

    % Enumerations provide faster matching than corresponding string properties
    % and we update them during setupImpl()
    properties (Nontunable,Hidden)
        % make these internal values index into the corresponding public
        % properties
        EnumRAMType = 1;
        EnumWriteOutputValue = 1;
        EnumVectorAccess = 1;
        NumBanks = 0; % intentionally invalid
        NumAccesses = 0; % intentionally invalid
        IsRowVector = false;
        IsStructRAM = false;

        % Flag to unionize read, write addresses if both are fixed-point but
        % have different numerictype. NOTE: this is applicable only for 'Simple
        % dual port' and 'Dual port' RAMTypes only, and it never changes from 1.
        UnionizeAddresses = 1;

        RamSize = 1;
        RamBankSize = 1;
        NumAddressBits = 1;
        RAMDirective = '';
        SynthesisAttributes = {};
    end

    properties (Constant, Hidden)
        % RAMType property
        RAMTypeStr = {...
            'Single port',...
            'Simple dual port',...
            'Dual port', ...
            'True dual port', ...
            'Simple tri port'};

        RAMTypeSet = matlab.system.StringSet(hdl.RAM.RAMTypeStr);

        % WriteOutputValue property
        WriteOutputValueStr = {...
            'New data',...
            'Old data'};

        WriteOutputValueSet = matlab.system.StringSet(hdl.RAM.WriteOutputValueStr);

        % VectorAccess property
        VectorAccessStr = {...
            'Parallel',...
            'Serial'};

        VectorAccessSet = matlab.system.StringSet(hdl.RAM.VectorAccessStr);
    end

    % properties (Hidden)
    %     VectorAccessSet = matlab.system.internal.DynamicStringSet(hdl.RAM.VectorAccessStr);
    % end

    properties (Access=private)
        % Remove discrete state property in lieu of simulation speedup
        % requests.

        % pRAM RAM memory.
        % Stores data that is sent in to be written
        pRAM

        % pOutWriteData Delayed output write data.
        % Stores output for write output port in the next step. This
        % simulates the one clock delay in RAM data access.
        pOutWriteData

        % pOutReadData Delayed output read data.
        % Stores output for read output port in the next step. This
        % simulates the one clock delay in RAM data access.
        pOutReadData
    end



    methods
        function obj = RAM(varargin)
            coder.internal.allowHalfInputs;
            %if nargin > 0
            %        [varargin{:}] = convertStringsToChars(varargin{:});
            %end

            % RAMType and WriteOutputValue can also be specified without
            % the pv-pair interface
            % obj.VectorAccessSet = matlab.system.internal.DynamicStringSet(hdl.RAM.VectorAccessStr);
            setProperties(obj, nargin, varargin{:}, ...
                'RAMType', 'WriteOutputValue', 'RAMInitialValue', ...
                'AsyncRead', 'ModelRAMDelay', 'VectorAccess', ...
                'allowBusInputs');
        end % hdl.RAM

        function output = get.EnumRAMType(obj)
            output = find(strcmp(obj.RAMType, obj.RAMTypeStr));
        end

        function writes = get.NumWrites(obj)
            switch obj.EnumRAMType
                case 4
                    writes = 2;
                otherwise
                    writes = 1;
            end
        end

        function reads = get.NumReads(obj)
            switch obj.EnumRAMType
                case {1, 4}
                    reads = 0;
                case 5
                    reads = 2;
                otherwise
                    reads = 1;
            end
        end

        function output = get.WritesHaveOutput(obj)
            switch obj.EnumRAMType
                case {2, 5}
                    output = false;
                otherwise
                    output = true;
            end
        end

        function output = get.WriteOutputValue(obj)
            if obj.EnumRAMType == 2 || obj.EnumRAMType == 5 || obj.AsyncRead
                % force write output to always be old data
                output = obj.WriteOutputValueStr{2};
            else
                output = obj.WriteOutputValue;
            end
        end

        function output = get.EnumWriteOutputValue(obj)
            output = find(strcmp(obj.WriteOutputValue, obj.WriteOutputValueStr));
        end

        function output = get.AsyncRead(obj)
            switch obj.EnumRAMType
                case 4
                    output = false;
                otherwise
                    output = obj.AsyncRead;
            end
        end

        % function set.AsyncRead(obj, val)
        %     obj.AsyncRead = val;
        %     obj.updateVectorAccessStringSet(val);
        % end

        function output = get.ModelRAMDelay(obj)
            if obj.AsyncRead
                % force simulate delay to be on since there is no delay for
                % reading anyway
                output = true;
            else
                output = obj.ModelRAMDelay;
            end
        end

        % function set.ModelRAMDelay(obj, val)
        %     obj.ModelRAMDelay = val;
        %     obj.updateVectorAccessStringSet(~val);
        % end

        function output = get.EnumVectorAccess(obj)
            if obj.AsyncRead || ~obj.ModelRAMDelay
                % option is valid
                val = obj.VectorAccess;
            else
                val = 'Parallel';
            end
            output = find(strcmp(val, obj.VectorAccessStr));
        end

    end


    methods(Access = protected) %Impls
        function num = getNumInputsImpl(obj)
            num = obj.NumReads + obj.NumWrites * 3;
        end % getNumInputsImpl

        function num = getNumOutputsImpl(obj)
            num = obj.NumReads;
            if(obj.WritesHaveOutput)
                num = num + obj.NumWrites;
            end
        end % getNumOutputsImpl

        function icon = getIconImpl(obj)
            switch(obj.EnumRAMType)
                case 1
                    icon = sprintf('Single Port\nRAM');
                case 2
                    icon = sprintf('Simple\nDual Port\nRAM');
                case 3
                    icon = sprintf('Dual Port\nRAM');
                case 4
                    icon = sprintf('True\nDual Port\nRAM');
                case 5
                    icon = sprintf('Simple\nTri Port\nRAM');
            end % switch-case (EnumRAMType)
            if ~obj.ModelRAMDelay
                icon = [icon sprintf('\n\nModel Delay\noff')];
            elseif obj.AsyncRead
                icon = [icon sprintf('\n\nAsync Read\non')];
            end
            if obj.EnumVectorAccess == 2 && (~obj.ModelRAMDelay || obj.AsyncRead) 
                icon = [icon sprintf('\n\nVector Access\nSerial')];
            end
            inputDT = obj.propagatedInputDataType(3);
            if ~isempty(inputDT)
                if ~ischar(inputDT) || ~strcmpi(inputDT, 'logical')
                    icon = [icon sprintf('\n\nColumn\nWrite')];
                end
            end
        end

        function varargout = getInputNamesImpl(obj)
            varargout = cell(1, getNumInputs(obj));
            portNum = 1;
            for i = 1:obj.NumWrites
                varargout{portNum} = hdl.RAM.portName('din',i, obj.NumWrites>1);
                varargout{portNum+2} = hdl.RAM.portName('we', i, obj.NumWrites>1);
                if(obj.NumReads > 0)
                    varargout{portNum+1} = hdl.RAM.portName('wr_addr', i, obj.NumWrites>1);
                else
                    varargout{portNum+1} = hdl.RAM.portName('addr', i, obj.NumWrites>1);
                end
                portNum = portNum + 3;
            end
            for i = 1:obj.NumReads
                if(obj.NumWrites > 0)
                    addrName = 'rd_addr';
                else
                    addrName = 'addr';
                end
                varargout{portNum} = hdl.RAM.portName(addrName, i, obj.NumReads>1);
                portNum = portNum + 1;
            end
        end % getInputNamesImpl

        function varargout = getOutputNamesImpl(obj)
            varargout = cell(1, getNumOutputs(obj));
            if(obj.EnumRAMType == 1)
                varargout{1} = 'dout';
            else
                portNum=1;
                if(obj.WritesHaveOutput)
                    if obj.NumReads > 0
                        outname = 'wr_dout';
                    else
                        outname = 'dout';
                    end
                    for i=1:obj.NumWrites
                        varargout{portNum} = hdl.RAM.portName(outname, i, obj.NumWrites>1);
                        portNum = portNum + 1;
                    end
                end

                if obj.WritesHaveOutput && obj.NumWrites > 0
                    outname = 'rd_dout';
                else
                    outname = 'dout';
                end
                for i=1:obj.NumReads
                    varargout{portNum} = hdl.RAM.portName(outname, i, obj.NumReads>1);
                    portNum = portNum + 1;
                end
            end
        end % getOutputNamesImpl

        function flag = isInactivePropertyImpl(obj, prop)
            % isInactivePropertyImpl
            % Output is true if the property passed in is inactive
            % Inactive cases:
            %   * AsyncRead when True Dual Port is selected
            %   * WriteOutputValue when there is no write output or when
            %     AsyncRead is true
            %   * ModelRAMDelay when AsyncRead is true
            %   * VectorAccess when ModelRAMDelay is true and AsyncRead is
            %     false
            flag = obj.EnumRAMType == 4 && strcmp(prop, 'AsyncRead') || ...
                (obj.EnumRAMType == 2 || obj.EnumRAMType == 5 || obj.AsyncRead) && strcmp(prop, 'WriteOutputValue') || ...
                obj.AsyncRead && strcmp(prop, 'ModelRAMDelay') || ...
                ~obj.AsyncRead && obj.ModelRAMDelay && strcmp(prop, 'VectorAccess') || ...
                ... permanently inactive properties
                strcmpi(prop, 'WritesHaveOutput') || strcmpi(prop, 'NumWrites') || strcmpi(prop, 'NumReads') ||  strcmpi(prop, 'allowBusInputs');
        end % isInactivePropertyImpl

        % function updateVectorAccessStringSet(obj, includeSerialOption)
        %     if includeSerialOption
        %         newValues = obj.VectorAccessStr;
        %     else
        %         newValues = {obj.VectorAccessStr{1}};
        %     end
        % 
        %     if ~contains(obj.VectorAccess, newValues)
        %         newValue = newValues{1};
        %     else
        %         newValue = obj.VectorAccess;
        %     end
        % 
        %     changeValues(obj.VectorAccessSet, newValues, obj, 'VectorAccess', newValue);
        % end

        function validateWeWordLengths(~, data, num_cols)
            if isa(data,'double')
                col_width = 64/num_cols;
            elseif isa(data,'single')
                col_width = 32/num_cols;
            elseif isa(data,'half')
                col_width = 16/num_cols;
            else
                col_width = fi(data).WordLength/num_cols;
            end
            coder.internal.assert(floor(col_width) == col_width,'hdlmllib:hdlmllib:RAMWordLengthMismatch');
        end

        function validateInputsImpl(obj, varargin)

            wrData1 = varargin{1};
            wrAddr1 = varargin{2};
            wrEn1 = varargin{3};

            maxSize = obj.getMaxInputSize(varargin);

            for i=1:obj.NumWrites
                data_idx = (i-1)*3+1;
                addr_idx = data_idx + 1;
                en_idx = data_idx + 2;
                wr_data = varargin{data_idx};
                wraddr = varargin{addr_idx};
                wr_en = varargin{en_idx};
                hdl.RAM.validateRAMaddresses(wrAddr1, wraddr);
                coder.internal.assert(hdl.RAM.typeCompare(wr_data, wrData1), ...
                    'hdlmllib:hdlmllib:RAMWriteDataSameType', ...
                    'IfNotConst', 'Fail');
                coder.internal.assert(hdl.RAM.typeCompare(wr_en, wrEn1), ...
                    'hdlmllib:hdlmllib:RAMWriteEnableSameType', ...
                    'IfNotConst','Fail');
                hdl.RAM.validateRAMWriteData(wr_data);
                hdl.RAM.validateRAMWriteEnable(wr_en, en_idx);
                if ~islogical(wr_en)
                    num_cols = fi(wr_en).WordLength;
                    if isstruct(wr_data)
                        fn = fieldnames(wr_data);
                        for j = 1:numel(fn)
                            data_i = wr_data(1).(fn{j});
                            obj.validateWeWordLengths(data_i, num_cols);
                        end
                    else
                        obj.validateWeWordLengths(wr_data, num_cols);
                    end
                end

                if(obj.WritesHaveOutput)
                    hdl.RAM.validateRAMAddress(wraddr, 'RAM read/write address', addr_idx);
                else
                    hdl.RAM.validateRAMAddress(wraddr, 'RAM write address', addr_idx);
                end
                if obj.EnumVectorAccess == 2
                    allSizesScalarOrEqual = ...
                        (isscalar(wr_data) || isequal(size(wr_data), maxSize)) && ...
                        (isscalar(wraddr) || isequal(size(wraddr), maxSize)) && ...
                        (isscalar(wr_en) || isequal(size(wr_en), maxSize));
                    coder.internal.errorIf(~allSizesScalarOrEqual, ...
                        'hdlmllib:hdlmllib:RAMNumAccessesNotSame');
                else
                    hdl.RAM.validateWriteBanks(wrData1, wrAddr1, wr_data, wraddr, wr_en);
                end
            end
            for i=1:obj.NumReads
                rd_addr_idx = obj.NumWrites*3+i;
                rdaddr = varargin{rd_addr_idx};
                hdl.RAM.validateRAMaddresses(wrAddr1, rdaddr);
                hdl.RAM.validateRAMAddress(rdaddr, 'RAM read address', rd_addr_idx);
                if obj.EnumVectorAccess == 2
                    allSizesScalarOrEqual = ...
                        (isscalar(rdaddr) || isequal(size(rdaddr), maxSize));
                    coder.internal.errorIf(~allSizesScalarOrEqual, ...
                        'hdlmllib:hdlmllib:RAMNumAccessesNotSame');
                else
                    hdl.RAM.validateReadBanks(wrData1, wrAddr1, rdaddr);
                end
            end
        end % validateInputsImpl

        function setupImpl(obj, varargin)
            % setupImpl
            % initialize RAM and delayed read/write data (with 0s or the ramIV).
            % The method inputs are the RAM object, followed by its inputs.
            % Simple Dual and Dual port RAMs have a 2nd address port, which is
            % provided in varargin{1}. The unused parameter in the argument list
            % is the write_enable signal.

            % if ambiguous/double types are passed in, provide a default
            % value and return.
            sizeCheckOnly = hdl.RAM.getSizeCheckStatus;
            if sizeCheckOnly
                maxSize = obj.getMaxInputSize(varargin);
                obj.pOutWriteData = zeros([obj.NumWrites maxSize]);
                obj.pOutReadData = zeros([obj.NumReads maxSize]);
                obj.pRAM = zeros(maxSize);
                return;
            end
            
            obj.setRAMSize(varargin);

            data_in = varargin{1};
            % Create a zero value of the correct type for a single element
            % of the RAM storage. This will be used to define the type of
            % the RAM storage.
            if ~isstruct(data_in)
                resetDataValue = hdl.RAM.getResetData(data_in(1), [obj.NumBanks 1]);
            else
                resetDataValue = data_in(1);
                fn = fieldnames(data_in(1));
                for i = 1:numel(fn)
                    resetDataValue.(fn{i}) = hdl.RAM.getResetData(data_in(1).(fn{i}), size(data_in(1).(fn{i})));
                end
            end
            icV = obj.RAMInitialValue;

            if isstruct(data_in)
                coder.internal.errorIf(any(icV(:)), ...
                    'hdlmllib:hdlmllib:RAMIVMustBeZeroForBusInput', class(data_in));
            end
            % Check for complexity; if complex input, initial value should
            % be complex too.
            if ~isreal(data_in) && ~isstruct(data_in)
                resetVal = complex(resetDataValue);
                icVal = complex(icV);
            else
                resetVal = resetDataValue;
                icVal = icV;
            end

            % Error checking on icVal
            if ~isempty(icVal)
                coder.internal.errorIf(~isnumeric(icVal), ...
                    'hdlmllib:hdlmllib:RAMIVMustBeNumeric')
            end

            % For each of the 3 output signals, initialize them with one
            % value of the correct data type and complexity, expanded to the
            % appropriate vector size based off the input data's size/shape.
            outsize = obj.getOutputSignalSize;
            if isstruct(data_in)
                if isscalar(icVal)
                    fn = fieldnames(data_in(1));
                    for i = 1:numel(fn)
                        field = fn{i};
                        data = data_in(1).(field);
                        dSize = size(data);
                        if isfloat(data) || isinteger(data)
                            resetVal.(field) = cast(repmat(icVal, dSize), 'like', data);
                        elseif islogical(data)
                            resetVal.(field) = boolean(repmat(boolean(icVal), dSize));
                        elseif isfimathlocal(data)
                            dataNumerictype = get(data, 'numerictype');
                            dataFiMath = get(data, 'fimath');
                            resetVal.(field) = fi(repmat(icVal, dSize), 'numerictype', dataNumerictype, ...
                                'fimath', dataFiMath);
                        else
                            dataNumerictype = get(data, 'numerictype');
                            resetVal.(field) = fi(repmat(icVal, dSize), 'numerictype', dataNumerictype);
                        end
                    end
                end
                obj.pRAM = repmat(resetVal, obj.RamSize, 1);
                obj.pOutWriteData = repmat(resetVal, [obj.NumWrites, outsize]);
                obj.pOutReadData = repmat(resetVal, [obj.NumReads, outsize]);
            elseif isempty(icVal)
                obj.pRAM = repmat(resetVal, obj.RamSize, 1);
                obj.pOutWriteData = repmat(resetVal, [obj.NumWrites outsize]);
                obj.pOutReadData = repmat(resetVal, [obj.NumReads outsize]);
            elseif isscalar(icVal)
                % If there's a IV, use it for the initial value. Use the
                % same type as already determined for the resetVal above.
                resetVal = cast(icVal, 'like', resetVal);
                % Assign the RAM matrix with the one value of the correct data
                % type and complexity, expanded to the total number of RAM
                % locations, including any multiple banks inferred from the
                % input data size.
                obj.pRAM = repmat(resetVal, obj.RamSize, 1);
                obj.pOutWriteData = repmat(resetVal, [obj.NumWrites outsize]);
                obj.pOutReadData = repmat(resetVal, [obj.NumReads outsize]);
            else
                coder.internal.errorIf((numel(icVal) ~= obj.RamBankSize)...
                    && (numel(icVal) ~= obj.RamBankSize*obj.NumBanks), ...
                    'hdlmllib:hdlmllib:UnsupportedIVSize',...
                    obj.NumBanks, obj.RamBankSize, numel(icVal), obj.NumBanks*obj.RamBankSize);

                % If the RAM IC is a matrix input and the size of the
                % matrix is not of the order mxn where m and n are the
                % no.of banks and the bank size, throw error
                % indicating the correct format.
                icValSize = size(icVal);
                coder.internal.errorIf(all(icValSize>1) && ...
                    ~(isequal(icValSize,[obj.RamBankSize obj.NumBanks])...
                    || isequal(icValSize,[obj.NumBanks obj.RamBankSize])), ...
                    'hdlmllib:hdlmllib:UnsupportedMatrixIVSize',...
                    obj.NumBanks, obj.RamBankSize, icValSize(1), icValSize(2));

                resetVal = cast(icVal(1), 'like', resetVal);
                % check if matrix IC values are provided
                if (isequal(icValSize,[obj.RamBankSize obj.NumBanks]))
                    obj.pRAM = reshape(cast(icVal,'like',resetVal), obj.RamSize, 1);
                    obj.pOutWriteData = repmat(cast(icVal(1,:),'like',resetVal),[obj.NumWrites 1]);
                    obj.pOutReadData = repmat(cast(icVal(1,:),'like',resetVal),[obj.NumReads 1]);
                elseif (isequal(icValSize,[obj.NumBanks obj.RamBankSize]))
                    obj.pRAM = reshape(cast(icVal.','like',resetVal), obj.RamSize, 1);
                    obj.pOutWriteData = repmat(cast(icVal(:,1).','like',resetVal),[obj.NumWrites 1]);
                    obj.pOutReadData = repmat(cast(icVal(:,1).','like',resetVal),[obj.NumReads 1]);
                else
                    % handle vector inputs to initialize all banks of
                    % RAM with unique IC values
                    % Use the full user-specified IV
                    if isrow(icVal)
                        val = icVal.';
                    else
                        val = icVal;
                    end

                    % handle vector inputs to initialize all banks of
                    % RAM with unique IC values
                    if obj.NumBanks>1 && (numel(icVal) == obj.RamSize)
                        val = reshape(cast(icVal,'like',resetVal),obj.RamBankSize,obj.NumBanks);
                        obj.pRAM = reshape(cast(val, 'like', resetVal), obj.RamSize, 1);
                        obj.pOutWriteData = repmat(cast(val(1,:),'like',resetVal), [obj.NumWrites 1]);
                        obj.pOutReadData = repmat(cast(val(1,:),'like',resetVal), [obj.NumReads 1]);
                    else
                        obj.pRAM = repmat(cast(val, 'like', resetVal), obj.NumBanks, 1);
                        obj.pOutWriteData = repmat(resetVal, [obj.NumWrites outsize]);
                        obj.pOutReadData = repmat(resetVal, [obj.NumReads outsize]);
                    end
                end
            end
        end % setupImpl

        function varargout = isInputDirectFeedthroughImpl(obj)
            % This logic looks complicated, but it is just saying:
            %    1. Read and Write Addresses are always direct feedthrough
            %    with ModelRAMDelay=off or AsyncRead=on
            %    2. Data and Write Enable are direct feedthrough if
            %    ModelRAMDelay=off and WriteOutputValue=New Data

            % start with last index to preallocate varargout cell array size
            numWrInputs = obj.NumWrites*3;
            for ii = (obj.NumReads:-1:1) + numWrInputs
                ... read address is direct feedthrough with async read or no delay
                    ... which both of these are also conditions for serial vector access
                    varargout{ii} = obj.AsyncRead || ~obj.ModelRAMDelay;
            end

            isDataOrWEInput = @(x) mod(x,3) == 1 || mod(x,3) == 0;
            isWrAddrInput = @(x) mod(x,3) == 2;
            for ii = numWrInputs:-1:1
                varargout{ii} = ...
                    obj.WritesHaveOutput && ...
                    ... serial vector access creates data dependencies on vector elements, so everything can directly feed through
                    (obj.EnumVectorAccess == 2 || ...
                    (... data and write enable are direct feedtrough with no delay and write output as new data
                    isDataOrWEInput(ii) && ...
                    ~obj.ModelRAMDelay  && obj.EnumWriteOutputValue == 1 || ...
                    ...  write address is direct feedthrough with async read or no delay
                    isWrAddrInput(ii) &&...
                    (obj.AsyncRead || ~obj.ModelRAMDelay) ...
                    ));
            end
        end

        function varargout = outputImpl(obj, varargin)
            % Output method is called before update method, so any
            % feedthrough behavior must be handled here. If feedthrough
            % behavior isn't needed, then simple reading of pOutReadData
            % and pOutWriteData is all that is needed. Feedthrough behavior
            % happens with either AsyncRead=true or ModelRAMDelay=false.
            sizeCheckOnly = hdl.RAM.getSizeCheckStatus;
            if sizeCheckOnly % size check mode, send dummy output
                outsize = obj.getMaxInputSize(varargin);
                for ii = nargout:-1:1
                    varargout{ii} = zeros(outsize);
                end
                return;
            end
            
            computeNewData(obj, varargin, true);

            % output read data
            % start with biggest index to preallocate varargout cell array
            outsize = obj.getOutputSignalSize;
            for ii = obj.NumReads:-1:1
                varargout{ii + obj.NumWrites*obj.WritesHaveOutput} = reshape(obj.pOutReadData(ii, :), outsize);
            end
            % output write data
            for ii = obj.NumWrites*obj.WritesHaveOutput:-1:1
                varargout{ii} = reshape(obj.pOutWriteData(ii, :), outsize);
            end
        end

        % Gain speedup by avoiding to validate data types and sizes are being
        % passed in process inputs, send output(s) validation is carried for
        % once in the setupImpl()
        function updateImpl(obj, varargin)
            % stepImpl
            % process inputs, send output, update state
            % read FIRST
            % compute the address type
            if(~coder.target('hdl') && obj.EnumRAMType == 4)
                % This is will fail at run-time if the user simulates a
                % model that has the same address for a read and write
                % or a write and another write.
                writeAddressViolation = any((varargin{2}==varargin{5}) & (varargin{3} | varargin{6}));
                coder.internal.warningIf(writeAddressViolation, 'hdlmllib:hdlmllib:RAMTDPSameAddress');
            end

            computeNewData(obj, varargin, false);
        end % stepImpl

        function computeNewData(obj, inputs, isOutputImpl)
            coder.inline('always'); % helps ensure isOutputImpl is seen as const
            fullyExecuteInOutputImpl = coder.const(obj.EnumVectorAccess == 2 || (~obj.ModelRAMDelay && obj.EnumWriteOutputValue == 1));
            fullyExecuteInUpdateImpl = coder.const(~obj.AsyncRead && obj.ModelRAMDelay);
            if (fullyExecuteInOutputImpl && ~isOutputImpl) || (fullyExecuteInUpdateImpl && isOutputImpl)
                % Either compute new data during outputImpl or updateImpl
                % depending on RAM modeling chosen, unless the RAM is
                % AsyncRead=true with VectorAccess=parallel or
                % ModelRAMDelay=false with WriteOutputValue=old. In both of
                % these cases, only some inputs are direct feedthrough
                % (only the address inputs).
                % This function should be a no-op for one of the callsites
                % and result in dead code that can be optimized away
                % otherwise.
                return;
            end
            % Execute read operations if execution is exclusive to
            % outputImpl or updateImpl or execution is done in both but
            % this is called in outputImpl. This is just a small runtime
            % optimization to not do a double update of read outputs if
            % they are already updated in outputImpl.
            executeReads = coder.const( ...
                (fullyExecuteInOutputImpl && isOutputImpl) || ...
                (fullyExecuteInUpdateImpl && ~isOutputImpl) || ...
                (~fullyExecuteInUpdateImpl && isOutputImpl));

            isDataStruct = coder.const(obj.IsStructRAM);
            scale = @(x, y) (x-1)*3 + y; % scale linear index for data, address, we input bundles
            numelNeeded = coder.const(obj.NumBanks*obj.NumAccesses);
            canonicalSize = @(x) repmat(x, [numelNeeded*(numel(x) ~= numelNeeded) + (numel(x) == numelNeeded), 1]);

            writeFirst = coder.const(obj.EnumWriteOutputValue == 1);

            % Collect all the inputs by type and canonicalize sizes
            rdAddr = cell(obj.NumReads, 1);
            for ii = 1:obj.NumReads
                rdAddr{ii} = obj.getAddressInput(canonicalSize(double(inputs{obj.NumWrites*3+ii})));
            end
            data = cell(obj.NumWrites, 1);
            wrAddr = cell(obj.NumWrites, 1);
            writeEn = cell(obj.NumWrites, 1);
            for ii = 1:obj.NumWrites
                data{ii} = canonicalSize(inputs{scale(ii, 1)});
                wrAddr{ii} = obj.getAddressInput(canonicalSize(double(inputs{scale(ii, 2)})));
                writeEn{ii} = canonicalSize(inputs{scale(ii, 3)});
            end

            % read/write to RAM, loop over RAM banks/accesses
            % We need this to be an iterative operation using a loop in
            % case the RAM is doing serial access. If the RAM is doing
            % parallel access via banks, then the address spaces don't
            % overlap anyway.
            % MATLAB Coder was unrolling this when it didn't need to because of
            % complex cell array indexing that uses loop indices inside
            % expressions, which can lead to bad codegen performance.
            coder.unroll(false); 
            for ii = 1:obj.NumBanks*obj.NumAccesses
                %% update read data first from RAM
                for jj = 1:obj.NumReads*executeReads
                    rdAddr_jj = rdAddr{jj};
                    obj.pOutReadData(jj, ii) = obj.pRAM(rdAddr_jj(ii));
                end
                %% update write data and RAM
                for jj = 1:obj.NumWrites
                    data_jj = data{jj};
                    data_ii = data_jj(ii);
                    wrAddr_jj = wrAddr{jj};
                    wrAddr_ii = wrAddr_jj(ii);
                    writeEn_jj = writeEn{jj};
                    writeEn_ii = writeEn_jj(ii);

                    if obj.WritesHaveOutput && ~writeFirst && executeReads
                        % read before write, old data
                        obj.pOutWriteData(jj, ii) = obj.pRAM(wrAddr_ii);
                    end

                    if ~fullyExecuteInOutputImpl && isOutputImpl
                        % RAM state does not get updated during outputImpl
                        continue;
                    end

                    if writeEn_ii
                        % writing will happen
                        if ~islogical(writeEn_ii)
                            % Column write only certain parts of input data.
                            % Replace parts of input data with parts of
                            % existing RAM data where each WE bit is false.
                            if ~isDataStruct
                                cellNames = 1;
                                fns = @(x) cellNames;
                                accessData = @(x, y) x;
                            else
                                cellNames = fieldnames(data_ii);
                                fns = @(x) cellNames{x};
                                accessData = @(x, y) x.(y);
                            end
                            ram_ii = obj.pRAM(wrAddr_ii);
                            for kk = 1:numel(cellNames)
                                % Loop for struct fields if input is struct/bus.
                                % Loop only executes once for non-struct input.
                                fn_kk = fns(kk);
                                data_kk = accessData(data_ii, fn_kk);
                                if isreal(data_kk)
                                    addrArr = hdl.RAM.getArrAtAddr(data_kk, writeEn_ii, accessData(ram_ii, fn_kk));
                                    data_kk = hdl.bits2word(addrArr,'like',data_kk);
                                else
                                    addrArrReal = hdl.RAM.getArrAtAddr(real(data_kk), writeEn_ii, real(accessData(ram_ii, fn_kk)));
                                    addrArrImag = hdl.RAM.getArrAtAddr(imag(data_kk), writeEn_ii, imag(accessData(ram_ii, fn_kk)));
                                    writeValReal = hdl.bits2word(addrArrReal, 'like', real(data_kk));
                                    writeValImag = hdl.bits2word(addrArrImag, 'like', imag(data_kk));
                                    data_kk = complex(writeValReal, writeValImag);
                                end
                                if ~isDataStruct
                                    % kk loop should only execute once
                                    data_ii = data_kk;
                                else
                                    data_ii.(fn_kk) = data_kk;
                                end
                            end
                        end

                        obj.pRAM(wrAddr_ii) = data_ii;
                    end

                    if obj.WritesHaveOutput && writeFirst
                        % read after write, new data
                        obj.pOutWriteData(jj, ii) = obj.pRAM(wrAddr_ii);
                    end
                end
            end
        end

        function resetImpl(obj) %#ok<MANU>
            % Hardware RAMs are not resettable; do nothing on reset.
        end

        function modes = getExecutionSemanticsImpl(obj) %#ok<MANU>
            % supported semantics
            modes = {'Classic', 'Synchronous'};
        end % getExecutionSemanticsImpl

        function s = saveObjectImpl(obj)
            % saveObjectImpl
            % save states & properties into output structure
            % Save the public properties
            s = saveObjectImpl@matlab.System(obj);
            if obj.isLocked
                s.pRAM = obj.pRAM;
                s.pOutWriteData = obj.pOutWriteData;
                s.pOutReadData = obj.pOutReadData;
            end
        end % saveObjectImpl

        function loadObjectImpl(obj, s, ~)
            % loadObjectImpl
            % load states & properties from input structure
            fn = fieldnames(s);
            obj.setObjPropertiesFromStructure(s, fn);
        end

        function setObjPropertiesFromStructure(obj, s, fn)
            % setObjPropertiesFromStructure
            % for the fieldnames passed in (fn), copy over the settings
            % from s to the object
            for ii = 1:numel(fn)
                obj.(fn{ii}) = s.(fn{ii});
            end
        end % loadObjectImpl

        function supported = supportsMultipleInstanceImpl(~)
            % Support in For Each Subsystem
            supported = true;
        end

        function flag = isInputSizeMutableImpl(~,~)
            % input arg may change size after locked
            flag = true;
        end

        function flag = isInputComplexityMutableImpl(~,~)
            % input arg may change complexity after locked
            flag = true;
        end

        function varargout = isOutputComplexImpl(obj)
            for i=1:(obj.NumWrites + obj.NumReads)
                varargout{i} = propagatedInputComplexity(obj,1);
            end
        end

        function varargout = getOutputSizeImpl(obj)
            maxSize = propagatedInputSize(obj, 1);
            for ii = 2:obj.getNumInputsImpl
                inSize = propagatedInputSize(obj, ii);
                if prod(maxSize) < prod(inSize)
                    maxSize = inSize;
                end
            end
            for ii = 1:obj.getNumOutputsImpl
                varargout{ii} = maxSize;
            end
        end

        function varargout = isOutputFixedSizeImpl(obj)
            for i=1:(obj.NumWrites + obj.NumReads)
                varargout{i} = propagatedInputFixedSize(obj,1);
            end
        end

        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            busType = obj.propagatedInputBusStructure(1);
            if ~isempty(busType) && (busType.isBus || busType.isPartial)
                % propagate output port as bus
                for i=1:getNumOutputsImpl(obj)
                    varargout{i} = busType;
                end
            else
                % if true, this is non-bus signal or undetermined
                % propagate output port as non-bus or undetermined
                inputType = obj.propagatedInputDataType(1);
                for i=1:getNumOutputsImpl(obj)
                    if isempty(inputType)
                        varargout{i} = Simulink.SignalDescriptor; % undetermined
                    else
                        varargout{i} = inputType; % determined non-bus
                    end
                end
            end
        end
    end % protected methods (Impls)



    methods(Access = protected) %non-Impls
        function address = getAddressInput(obj, addressIn)
            % Banked RAM is stored as a single RAM, with each bank sequentially
            % ordered. For each RAM bank, add offset corresponding to its number
            % to get the absolute address within RAM array. Send it as is, if fi
            % or integer, else if double/single, convert to uint16 and send out.
            isUsingBanks = coder.const(obj.NumBanks > 1);
            relAddress = addressIn + isUsingBanks * reshape(obj.RamBankSize*(0:numel(addressIn)-1), size(addressIn));
            address = double(fi(relAddress, 0, obj.NumAddressBits, 0)) + 1;
        end % getAddressInput
        function type = computeAddrUnion(obj, argin)
            sizeCheckOnly = hdl.RAM.getSizeCheckStatus;
            maxBits = 0;
            if(~sizeCheckOnly)
                for ii = 1:obj.NumWrites
                    addr = argin{(ii-1)*3+2};
                    maxBits = max(maxBits,hdl.RAM.getNumAddressBits(addr));
                end
                for ii = 1:obj.NumReads
                    addr = argin{obj.NumWrites*3+ii};
                    maxBits = max(maxBits,hdl.RAM.getNumAddressBits(addr));
                end
                type = numerictype(0, maxBits, 0);
            else
                type = numerictype(0, hdl.RAM.getNumAddressBits(argin{2}), 0);
            end
        end

        function setRAMSize(obj, varargin)
            % Get RAM size (all banks)
            % Call in setupImpl
            % valid data types and sizes are being passed in
            % get the number of locations in the RAM
            [data, address, weIn] = obj.getMaxInputsBySize(varargin{1});

            numData = numel(data);
            if isstruct(data)
                obj.IsStructRAM = true;
            else
                obj.IsStructRAM = false;
            end
            if obj.EnumVectorAccess == 1
                % parallel vector access
                % data input assumed to be vector size needed
                obj.NumBanks = numData;
                obj.NumAccesses = 1;
                obj.IsRowVector = isrow(data);
            else
                % serial vector access
                % number of accesses can be defined either by data or addr
                % inputs
                obj.NumBanks = 1;
                obj.NumAccesses = max([numData, numel(address), numel(weIn)]);
                obj.IsRowVector = (~isscalar(data) && isrow(data)) || (~isscalar(address) && isrow(address)) || (~isscalar(weIn) && isrow(weIn));

                coder.internal.errorIf(obj.IsStructRAM && obj.NumAccesses > 1, 'hdlmllib:hdlmllib:UnsupportedArrayOfBusesRAMSerial');
            end

            obj.RamBankSize = hdl.RAM.calculateRAMBankSize(address(1));

            % Total number of addresses in the RAM
            obj.RamSize = obj.NumBanks*obj.RamBankSize;

            % Total number of address bits needed to represent all addresses.
            obj.NumAddressBits = ceil(log2(obj.RamSize));

            data1 = data(1);
            if isfi(data1)
                dataBytes = data1.WordLength;
            elseif isstruct(data1)
                dataBytes = hdl.RAM.getStructDataBytes(data1);
            elseif isa(data1, 'single') || isa(data1, 'int32') || isa(data1, 'uint32')
                dataBytes = 4;
            elseif isa(data1, 'double') || isa(data1, 'int64') || isa(data1, 'uint64')
                dataBytes = 8;
            elseif isa(data1, 'int16') || isa(data1, 'uint16') || isa(data1, 'half')
                dataBytes = 2;
            elseif isa(data1, 'int8') || isa(data1, 'uint8') || islogical(data1)
                dataBytes = 1;
            else
                isSupported = false;
                coder.internal.assert(isSupported, 'hdlmllib:hdlmllib:UnsupportedDataTypeForHDLRam', class(data1), ...
                    'IfNotConst', 'Fail');
            end
            bitsForData = log2(dataBytes);
            % The total number of bits to byte-address the RAM contents is the
            % sum of:
            %  1) The number of address bits in the RAM, which includes the RAM
            %  banking
            %  2) The number of address bits needed to *byte* address a RAM
            %  word. This is computed above in bitsForData.
            totalBits = obj.NumAddressBits + bitsForData;
            coder.internal.errorIf(totalBits > 31, 'hdlmllib:hdlmllib:RAMTooLarge');
        end % setRAMSize

        function maxSize = getMaxInputSize(obj, varargin)
            [data, address, weIn] = obj.getMaxInputsBySize(varargin{1});
            maxNumel = max([numel(data), numel(address), numel(weIn)]);
            if (~isscalar(data) && isrow(data)) || (~isscalar(address) && isrow(address)) || (~isscalar(weIn) && isrow(weIn))
                % row vector input
                maxSize = [1 maxNumel];
            else
                maxSize = [maxNumel 1];
            end
        end

        function [data, address, we] = getMaxInputsBySize(obj, varargin)
            inputs = varargin{1};
            maxSizeIdx = @(x) find(cellfun(@(y) numel(y), x) == max(cellfun(@(y) numel(y), x)), 1);

            dataIdx = 1:3:obj.NumWrites*3;
            wrAddrIdx = dataIdx+1;
            weIdx = wrAddrIdx+1;

            dataIns = cell(numel(dataIdx), 1);
            for ii = 1:numel(dataIdx)
                dataIns{ii} = inputs{dataIdx(ii)};
            end

            wrAddrIns = cell(numel(wrAddrIdx), 1);
            for ii = 1:numel(wrAddrIdx)
                wrAddrIns{ii} = inputs{wrAddrIdx(ii)};
            end

            weIns = cell(numel(weIdx), 1);
            for ii = 1:numel(weIdx)
                weIns{ii} = inputs{weIdx(ii)};
            end

            data = dataIns{maxSizeIdx(dataIns)};
            wrAddrIn = wrAddrIns{maxSizeIdx(wrAddrIns)};
            we = weIns{maxSizeIdx(weIns)};

            if obj.NumReads > 0
                % find biggest size address input between both read and
                % write
                rdAddrIdx = (1:obj.NumReads)+3*obj.NumWrites;
                rdAddrIns = cell(numel(rdAddrIdx), 1);
                for ii = 1:numel(rdAddrIdx)
                    rdAddrIns{ii} = inputs{rdAddrIdx(ii)};
                end

                rdAddrIn = rdAddrIns{maxSizeIdx(rdAddrIns)};

                if isfi(wrAddrIn) && isfi(rdAddrIn) && obj.UnionizeAddresses
                    unionType = obj.computeAddrUnion(inputs);
                    if numel(rdAddrIn) > numel(wrAddrIn)
                        address = fi(zeros(size(rdAddrIn)), unionType);
                    else
                        address = fi(zeros(size(wrAddrIn)), unionType);
                    end
                elseif numel(rdAddrIn) > numel(wrAddrIn)
                    address = rdAddrIn;
                else
                    address = wrAddrIn;
                end
            else
                address = wrAddrIn;
            end
        end

        function val = getOutputSignalSize(obj)
            if obj.IsRowVector
                val = coder.const([1 obj.NumBanks*obj.NumAccesses]);
            else
                val = coder.const([obj.NumBanks*obj.NumAccesses 1]);
            end
        end

    end % protected methods (non-Impls)



    methods(Static, Access=private)
        function name = portName(basename, num, includeNum)
            if(includeNum)
                name = sprintf('%s_%c', basename, char('a'+num-1));
            else
                name = basename;
            end
        end

        function validateWriteBanks(refData, refAddr, writeData, writeAddr, writeEnable)
            scalar = isscalar(refAddr);
            if(isscalar(writeAddr) && isscalar(writeData) && isscalar(writeEnable) && scalar)
                return
            end
            isInputNonScalarVector = ~isvector(writeData) || ~isvector(writeAddr) || ...
                ~isvector(writeEnable);

            coder.internal.errorIf(isInputNonScalarVector, ...
                'hdlmllib:hdlmllib:RAMNonScalarVector');
            % Each input have to have same dimension corresponding to the
            % number of RAM banks
            writeDataSize = size(writeData);
            writeAddressSize = size(writeAddr);
            writeEnableSize = size(writeEnable);

            refSize = size(refAddr);
            vectorWrite = ~isscalar(writeData) && scalar && ...
                isequal(writeDataSize, size(refData));
            % Verify all sizes are same
            isSpecifiedNumBanksSame =  ...
                (isequal(writeDataSize, refSize) || vectorWrite) && ...
                isequal(writeAddressSize, refSize) && ...
                isequal(writeEnableSize, refSize);

            coder.internal.errorIf(~isSpecifiedNumBanksSame, ...
                'hdlmllib:hdlmllib:RAMNumBanksNotSame');
        end

        function validateReadBanks(refData, refAddr, readAddr)
            scalar = isscalar(refAddr);
            if(isscalar(refData) && isscalar(readAddr) && scalar)
                return
            end
            isInputNonScalarVector = ~isvector(readAddr);

            coder.internal.errorIf(isInputNonScalarVector, ...
                'hdlmllib:hdlmllib:RAMNonScalarVector');

            % Each input have to have same dimension corresponding to the
            % number of RAM banks
            readAddrSize = size(readAddr);
            refSize = size(refAddr);

            % Verify all sizes are same
            isSpecifiedNumBanksSame =  ...
                isequal(refSize, readAddrSize);
            % Verify usage is valid for vector mode
            isVectorMode = ~isscalar(refData) && ...
                isscalar(refAddr) && ...
                isscalar(readAddr);

            coder.internal.errorIf(~(isSpecifiedNumBanksSame || isVectorMode), ...
                'hdlmllib:hdlmllib:RAMNumBanksNotSame');
        end

        function validateRAMWriteData(writeData)
            %Check for ufix1, nested bus and other unsupported data
            %types for struct input
            if isstruct(writeData)
                hdl.RAM.getStructDataBytes(writeData);
            end
            for nn = 1:length(writeData)
                % Write data must be scalar, fixed point or numeric
                validateattributes(writeData(nn), {'numeric', 'embedded.fi','struct','logical'}, ...
                    {'scalar'},...
                    'hdl.RAM', 'RAM write data', 1);
            end
        end % validateRAMWriteData

        function validateRAMWriteEnable(writeEnable, j)
            for nn = 1:length(writeEnable)
                % wrEn input must be logical or numeric, real, and scalar
                validateattributes(writeEnable(nn), {'logical','uint8','uint16','uint32','uint64','embedded.fi'},...
                    {'real','scalar'}, 'hdl.RAM', 'RAM write enable', j);
                if isnumeric(writeEnable(nn)) && ~coder.internal.isAmbiguousTypes
                    % need the additional condition to prevent the
                    % assertions from firing during size propagation when
                    % system object is used inside MLFB
                    coder.internal.assert(~issigned(fi(writeEnable(nn))),'hdlmllib:hdlmllib:RAMWeSigned');
                    coder.internal.assert(fi(writeEnable(nn)).FractionLength == 0, 'hdlmllib:hdlmllib:RAMWeFraction');
                end
            end
        end % validateRAMWriteEnable

        function validateRAMBankAddress(address, addressString, addressIndex)
            % Validate RAM address
            % should be real (not complex), scalar
            % HDL validation: between 2 and 32 bits (unless single or double)
            % unsigned fi, uint8, or uint32

            % size validation - check for real, scalar value
            % unsigned integer, unsigned embedded.fi, single or double
            validateattributes(address, ...
                {'single', 'double', 'uint8', 'uint16','embedded.fi'}, ...
                {'scalar', 'real'}, ...
                'hdl.RAM', addressString, addressIndex);

            % This check is implemented only if the types are not ambiguous
            % and need to be checked
            sizeCheckOnly = hdl.RAM.getSizeCheckStatus;
            if ~sizeCheckOnly && isfi(address)
                % if embedded.fi, unsigned, between 2 and 31 bit (inclusive)
                s = get(address, 'Signedness');
                wl = get(address, 'WordLength');
                fl = get(address, 'FractionLength');
                invalidAddress = (strcmpi(s, 'Signed')) ||...
                    (wl < 2 || wl > 31) || (fl ~= 0);
                coder.internal.errorIf(invalidAddress,...
                    'hdlmllib:hdlmllib:RAMAddress', addressIndex, addressString);
            end
        end % validateRAMBankAddress

        function validateRAMAddress(address, addressString, addressIndex)
            % Validate each RAM bank address
            % should be real (not complex), scalar
            % HDL validation: between 1 and 31 bits (unless single or double)
            % unsigned fi, uint8/16
            for nn = 1:length(address)
                hdl.RAM.validateRAMBankAddress(address(nn), addressString, addressIndex);
            end
        end % validateRAMAddress

        function validateRAMaddresses(ref, addresses)
            % check that all addresses are the same size
            % checking just the number of bits, assuming fraction length
            % and signedness are checked elsewhere

            % this check is implemented only if the types are not ambiguous
            % and need to be checked
            sizeCheckOnly = hdl.RAM.getSizeCheckStatus;
            if ~sizeCheckOnly
                size = hdl.RAM.calculateRAMBankSize(ref);
                addressSize = hdl.RAM.calculateRAMBankSize(addresses);
                if(addressSize ~= size)
                    coder.internal.assert(false, 'hdlmllib:hdlmllib:ReadWriteAddressNotSame');
                end
            end % ~sizeCheckOnly
        end % validateWriteReadAddresses

        function sizeCheckOnly = getSizeCheckStatus
            % return true if we are in check sizes only mode
            % in this case, a lot of validation is disabled and dummy
            % outputs are returned
            sizeCheckOnly = (~isempty(coder.target) && eml_ambiguous_types);
        end
        % getSizeCheckStatus

        function dataBytes = getStructDataBytes(data)
            % return bytes required to store the struct elements

            dataBytes = 0;
            fn = fieldnames(data);
            for i = 1:numel(fn)
                data1 = data(1).(fn{i});
                if isfi(data1)
                    tempBytes = data1.WordLength;
                elseif isenum(data1)
                    isSupported = false;
                    coder.internal.assert(isSupported, 'hdlmllib:hdlmllib:UnsupportedDataTypeForHDLRam', class(data1), ...
                        'IfNotConst', 'Fail');
                elseif isa(data1, 'single') || isa(data1, 'int32') || isa(data1, 'uint32')
                    tempBytes = 4;
                elseif isa(data1, 'double') || isa(data1, 'int64') || isa(data1, 'uint64')
                    tempBytes = 8;
                elseif isa(data1, 'int16') || isa(data1, 'uint16') || isa(data1, 'half')
                    tempBytes = 2;
                elseif isa(data1, 'int8') || isa(data1, 'uint8') || islogical(data1)
                    tempBytes = 1;
                elseif isstruct(data1)
                    isSupported = false;
                    coder.internal.assert(isSupported, ...
                        'hdlmllib:hdlmllib:UnsupportedNestedBusTypeForHDLRam');
                else
                    isSupported = false;
                    coder.internal.assert(isSupported, 'hdlmllib:hdlmllib:UnsupportedDataTypeForHDLRam', class(data1), ...
                        'IfNotConst', 'Fail');
                end
                dataBytes = dataBytes + tempBytes;
            end
            dataBytes = dataBytes*numel(data);
        end %getStructDataBytes

        function addrArr = getArrAtAddr(data_n, writeEn, addrVal)
                num_cols = fi(writeEn).WordLength;
                switch class(data_n)
                    case 'double'
                        bits = 64;
                    case 'single'
                        bits = 32;
                    case 'half'
                        bits = 16;
                    otherwise
                        bits = fi(data_n).WordLength;
                end
                col_width = bits/num_cols;
                datavec = hdl.word2bits(data_n, bits);
                wrEnArr = hdl.word2bits(writeEn, num_cols);
                addrArr = hdl.word2bits(addrVal, num_cols*col_width);
                for col = 1:num_cols
                    if wrEnArr(col)
                        idxRange = 1+(col-1)*col_width:col*col_width;
                        addrArr(idxRange) = datavec(idxRange);
                    end
                end
            end

        function resetDataValue = getResetData(data_in, outsize)
            if isenum(data_in)
                isSupported = false;
                coder.internal.assert(isSupported, 'hdlmllib:hdlmllib:UnsupportedDataTypeForHDLRam', class(data_in), ...
                    'IfNotConst', 'Fail');
            elseif isfloat(data_in) || isinteger(data_in) || islogical(data_in)
                resetDataValue = cast(zeros(outsize), 'like', data_in);
            else % fi
                dataNumerictype = get(data_in, 'numerictype');
                if isfimathlocal(data_in)
                    dataFiMath = get(data_in, 'fimath');
                    resetDataValue = fi(zeros(outsize), 'numerictype', dataNumerictype, ...
                        'fimath', dataFiMath);
                else
                    resetDataValue = fi(zeros(outsize), 'numerictype', dataNumerictype);
                end
            end
        end

        function sameType = typeCompare(a, b)
            if xor(isreal(a), isreal(b))
                sameType = false;
            elseif(isfi(a) && isfi(b))
                sameType = a.WordLength == b.WordLength && a.Signed == b.Signed ...
                    && a.FractionLength == b.FractionLength;
            else
                sameType = strcmp(class(a), class(b));
            end
        end

        function numAddressBits = getNumAddressBits(address) % Get RAM bank size
            % address is unsigned integer, fi, double or single
            % check if address is integer
            if isinteger(address)
                switch class(address)
                    case 'uint8'
                        numAddressBits = 8;
                    case 'uint16'
                        numAddressBits = 16;
                    case 'uint32'
                        numAddressBits = 32;
                    case 'uint64'
                        numAddressBits = 64;
                    otherwise % case 'uint16'
                        numAddressBits = 16;
                end
            elseif isfi(address) % fi
                numAddressBits = get(address, 'WordLength');
            else % double, single
                numAddressBits = 16;
            end
        end

        function ramBankSize = calculateRAMBankSize(address)
            ramBankSize = 2^(hdl.RAM.getNumAddressBits(address));
        end % getRAMBankSize

    end % static private methods

    methods (Static, Access=protected)
        function isVisible = showSimulateUsingImpl
            % Do not show 'simulate using' option on mask. This must be set to
            % 'false' before submission if changed to 'true' for debugging purposes.
            isVisible = false;
        end

        function groups = getPropertyGroupsImpl
            % Split properties into Main and Advanced tabs

            advancedProperties = {'ModelRAMDelay', 'VectorAccess'};
            mainProperties = setdiff(properties('hdl.RAM'), advancedProperties, 'stable');

            tab1 = matlab.system.display.SectionGroup(...
                'Title', 'Main', ...
                'PropertyList',  mainProperties);

            tab2 = matlab.system.display.SectionGroup(...
                'Title', 'Advanced', ...
                'PropertyList',  advancedProperties);

            groups = [tab1, tab2];
        end
    end

end % hdl.RAM

% LocalWords:  RAMIV RAMTDPSameAddress mxn impl kk
