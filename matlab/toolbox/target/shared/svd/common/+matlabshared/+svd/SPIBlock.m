classdef (StrictDefaults)SPIBlock < matlabshared.svd.SPI

    %SPIMASTERBLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    %#codegen

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Nontunable)
        % BlockFunction Block functionality
        BlockFunction = 'Transfer';
        % RegisterAddress Register address
        RegisterAddress = 0;
        % OutputDataType Output data type
        OutputDataType = 'int8';
        % OutputDataLength Output data length
        OutputDataLength = 1;
    end
    
    properties (Nontunable, Hidden)
        %OutputStatus Output status
        OutputStatus (1, 1) logical = false;
    end
    
    properties (Constant, Hidden)
        OutputDataTypeSet = matlab.system.StringSet({'int8','uint8','int16','uint16','int32','uint32','single','double'});
        BlockFunctionSet = matlab.system.StringSet({'Read','Write','Transfer'});
        READ_FROM_SLAVE = uint8(0);
        WRITE_TO_SLAVE = uint8(1);
        TRANSFER_BETWEEN_SLAVE_AND_MASTER = uint8(2);
    end
    
    properties (Dependent, Hidden, Nontunable)
        BlockFunctionEnum
    end
    
    methods
        function obj = SPIBlock(varargin)
            coder.allowpcode('plain');
            
            obj = obj@matlabshared.svd.SPI(varargin{:});
            
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function ret = get.BlockFunctionEnum(obj)
            if isequal(obj.BlockFunction, 'Read')
                ret = obj.READ_FROM_SLAVE;
            elseif isequal(obj.BlockFunction, 'Write')
                ret = obj.WRITE_TO_SLAVE;
            else
                ret = obj.TRANSFER_BETWEEN_SLAVE_AND_MASTER;
            end
        end
        
        function set.OutputDataLength(obj, value)
            validateattributes(value, {'numeric'}, {'scalar','positive','integer','finite','nonnan','nonempty','<',2^31}, '', 'Output data length');
            
            obj.OutputDataLength = value;
        end
        
        function set.RegisterAddress(obj, value)
            obj.validateRegisterAddress(value);
            
            obj.RegisterAddress = uint8(value);
        end
    end

    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SPI(obj, prop);
            switch prop
                case {'OutputDataType','OutputDataLength'}
                    flag = ~isequal(obj.BlockFunction, 'Read');
                case {'RegisterAddress'}
                    if isequal(obj.Mode, 'Master')
                        flag = isequal(obj.BlockFunction, 'Transfer');
                    else
                        flag = true;
                    end
                case 'BlockFunction'
                    flag = true;
            end
        end
        
        function validateInputsImpl(obj,varargin)
            % Validate inputs to the step method at initialization
            % Run this always in Simulation
            if isempty(coder.target)
                if (1 == getNumInputsImpl(obj))
                    validateattributes(varargin{1},{'numeric'},...
                        {'vector'},'','Data');
                end
            end
        end
        
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            % Initialise SPI Module
            open(obj);
        end
        
        function varargout = stepImpl(obj, varargin)
            % Set the bus speed from the parameter
            if ~isempty(obj.Hw) && getBusSpeedParameterVisibility(obj.Hw, obj.SPIModule)
                % Set bus speed for SPI
                setBusSpeed(obj);
            end
            
            if isequal(obj.BlockFunctionEnum, obj.WRITE_TO_SLAVE)
                status = writeRegister(obj, obj.RegisterAddress, varargin{1}, class(varargin{1}));
            elseif isequal(obj.BlockFunctionEnum, obj.READ_FROM_SLAVE)
                [rdData, status] = readRegister(obj, obj.RegisterAddress, uint32(obj.OutputDataLength), obj.OutputDataType);
            else
                [rdData, status] = writeRead(obj, varargin{1}, class(varargin{1}));
            end
            
            index = 1;
            if isequal(obj.BlockFunctionEnum, obj.READ_FROM_SLAVE) || ...
                    isequal(obj.BlockFunctionEnum, obj.TRANSFER_BETWEEN_SLAVE_AND_MASTER)
                varargout{index} = rdData;
                index = index + 1;
            end
            
            if obj.OutputStatus
                varargout{index} = status;
            end
        end        

        function releaseImpl(obj)
            close(obj);
        end

        function num = getNumInputsImpl(obj)
            % Define total number of inputs for system with optional inputs
            num = 0;
            switch obj.BlockFunction
                case {'Write','Transfer'}
                    num = 1;
            end
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of inputs for system with optional inputs
            num = 0;
            switch obj.BlockFunction
                case {'Read', 'Transfer'}
                    num = 1;
            end
            
            if obj.OutputStatus
                num = num + 1;
            end
        end

        function varargout = getInputNamesImpl(obj)
            % Return input port names for System block
            switch obj.BlockFunction
                case {'Write','Transfer'}
                    varargout{1} = 'SDO';
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            % Return input port names for System block
            index = 1;
            switch obj.BlockFunction
                case {'Read', 'Transfer'}
                    varargout{1} = 'SDI';
                    index = index + 1;
            end
            if obj.OutputStatus
                varargout{index} = 'Status';
            end
        end

        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            index = 1;
            switch obj.BlockFunction
                case 'Transfer'
                    varargout{index} = propagatedInputSize(obj,1);
                    index = index + 1;
                case 'Read'
                    varargout{index} = [double(obj.OutputDataLength) 1];
                    index = index + 1;
            end
            
            % Status output port data type
            if obj.OutputStatus
                varargout{index} = [1 1];
            end
        end

        function varargout = getOutputDataTypeImpl(obj)
            % Output port data type
            index = 1;
            switch obj.BlockFunction
                case 'Transfer'
                    varargout{index} = propagatedInputDataType(obj,1);
                    index = index + 1;
                case 'Read'
                    varargout{index} = obj.OutputDataType;
                    index = index + 1;
            end
            
            % Status output port data type
            if obj.OutputStatus
                varargout{index} = 'uint8';
            end
        end
    end
    
    methods (Access=protected)
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            if isequal(obj.BlockFunction,'Transfer')
                BlockFunctionStr = 'Controller';
            else
                BlockFunctionStr = 'Register';
            end
            BlockFunctionStr = sprintf('%s %s',BlockFunctionStr,obj.BlockFunction);
            
            maskDisplayCmds = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,60,''\fontsize{12}\bfSPI'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,40,''\fontsize{10}\bf' BlockFunctionStr ''',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,15,''Chip select: ' num2str(obj.Pin) ''' ,''horizontalAlignment'', ''center'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','SPI Block', ...
                'Text', ['Read data from an SPI peripheral device or an SPI peripheral device register.' newline newline ...
                'The block outputs the values received as an [Nx1] array.']);
        end
        
        function [groups, PropertyListMain, PropertyListAdvanced] = getPropertyGroupsImpl
            [groups, PropertyListMainOut, PropertyListAdvancedOut] = matlabshared.svd.SPI.getPropertyGroupsImpl;

            % Block property list
            % BlockFunction Block functionality
            BlockFunctionProp = matlab.system.display.internal.Property('BlockFunction', 'Description', 'svd:svd:SPIBlockFunctionPrompt');
            % RegisterAddress Register address
            RegisterAddressProp = matlab.system.display.internal.Property('RegisterAddress', 'Description', 'svd:svd:SPIRegisterAddressPrompt');
            % OutputDataType Output data type
            OutputDataTypeProp = matlab.system.display.internal.Property('OutputDataType', 'Description', 'svd:svd:SPIOutputDataTypePrompt');
            % OutputDataLength Output data length
            OutputDataLengthProp = matlab.system.display.internal.Property('OutputDataLength', 'Description', 'svd:svd:SPIOutputDataLengthPrompt');
        
            % Add to Main tab of mask
            PropertyListMainOut{end+1} = BlockFunctionProp;
            PropertyListMainOut{end+1} = RegisterAddressProp;
            PropertyListMainOut{end+1} = OutputDataTypeProp;
            PropertyListMainOut{end+1} = OutputDataLengthProp;
%             %OutputStatus Output status
%             OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'Output status');
%             PropertyListMainOut{end+1} = OutputStatusProp;
            
            % Update the property list
            groups(1).PropertyList = PropertyListMainOut;
            
            % Output property list if requested
            if nargout > 1
                PropertyListMain = PropertyListMainOut;
                PropertyListAdvanced = PropertyListAdvancedOut;
            end
        end        
    end
end
