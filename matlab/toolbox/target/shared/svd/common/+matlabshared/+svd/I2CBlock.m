classdef (StrictDefaults)I2CBlock < matlabshared.svd.I2C
    % Interfaces to access I2C bus from block
    %
    
    
    %#codegen
    %#ok<*EMCA>
    
    % Copyright 2015-2021 The MathWorks, Inc.
    
    properties (Nontunable)
        %Direction Direction
        Direction = 'Receiver';
    
        %RegisterAddressMode Enable register access
        RegisterAddressMode (1, 1) logical = true;
    
        %RegisterAddress Slave register address
        RegisterAddress = 0;
        %SlaveDataType Data type
        SlaveDataType = 'uint8';
        %DataLength Data size (N)
        DataLength = 1;
    
        %NoAck Send NACK at the end of data transfer
        NoAck (1, 1) logical = false;
        %RepeatedStart Remove stop bit at the end of data transfer
        RepeatedStart (1, 1) logical = false;
        %OutputStatus Output error status
        OutputStatus (1, 1) logical = false;
    end
    
    % Pre-computed constants.
    properties (Access = private)
        
    end
    
    properties (Constant, Hidden)
        DirectionSet = matlab.system.StringSet({'Receiver','Transmitter'});
        SlaveDataTypeSet = matlab.system.StringSet({ ...
            'int8','uint8',...
            'int16','uint16'...
            'int32','uint32'...
            'single','double'});
    end
    
    properties (Dependent, Access=protected)
        DirectionEnum
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = I2CBlock(varargin)
            obj = obj@matlabshared.svd.I2C(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function ret = get.DirectionEnum(obj)
            if isequal(obj.Direction,'Receiver')
                ret = SVDTypes.MW_Input;
            else
                ret = SVDTypes.MW_Output;
            end
        end
        
        function set.RegisterAddress(obj, value)            
            validateRegisterAddress(obj, value);
            
            obj.RegisterAddress = uint8(value);
        end

        function set.DataLength(obj, value)            
            validateattributes(value,{'numeric'}, {'nonnegative','scalar','integer','finite','nonnan','nonempty','<',2^31}, '', 'Data size (N)');
            
            obj.DataLength = value;
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            % Initialise I2C Module
            open(obj);
            
            if ~isempty(obj.Hw)
                setBusSpeed(obj, getI2CBusSpeedInHz(obj.Hw, obj.I2CModule));
            else
                % Default bus speed for I2C
                setBusSpeed(obj, 100000);
            end
            
            % Set the address of slave.  This is only used when the device
            % is slave.
            setSlaveAddress(obj);
        end
        
        function varargout = stepImpl(obj,varargin)
            if obj.DirectionEnum == SVDTypes.MW_Input
                if obj.RegisterAddressMode
                    [output, status] = readRegister(obj, obj.RegisterAddress, obj.DataLength, obj.SlaveDataType);
                else
                    [output, status] = read(obj, obj.DataLength, obj.SlaveDataType, obj.RepeatedStart, obj.NoAck);
                end
                varargout{1} = output;
                if nargout > 1
                    varargout{2} = status;
                end
            else
                data = varargin{1};
                
                if obj.RegisterAddressMode
                    status = writeRegister(obj, obj.RegisterAddress, data, class(data));
                else
                    status = write(obj, data, class(data), obj.RepeatedStart, obj.NoAck);
                end
                if nargout <= 1
                    varargout{1} = status;
                end
            end
        end
        
        function releaseImpl(obj)
            close(obj);
        end
        
        function flag = isInactivePropertyImpl(obj,propertyName)
            % Default all are active properties
            flag = false;
            
            % Parameters active Slave mode
            if (obj.ModeEnum == SVDTypes.MW_Slave)
                switch (propertyName)
                    case {'RegisterAddressMode','RegisterAddress',...
                            'RepeatedStart'}
                        flag = true;
                end
            % Parameters active Master mode
            else
                switch (propertyName)
                    case 'RegisterAddress'
                        flag = ~obj.RegisterAddressMode;
                    case {'RepeatedStart','NoAck'}
                        flag = obj.RegisterAddressMode;
                end
            end
            
            % Parameters active in Read mode
            if obj.DirectionEnum == SVDTypes.MW_Output
                switch (propertyName)
                    case {'SlaveDataType','DataLength'}
                        flag = true;
                end
            end
        end
        
        function validateInputsImpl(obj,varargin)
            % Run this always in Simulation
            if isempty(coder.target)
                if (1 == getNumInputsImpl(obj))
                    validateattributes(varargin{1},{'numeric'},...
                        {'vector'},'','Data');
                end
            end
        end
    end
    
    %% Define input/output dimensions
    methods (Access=protected)  
        function num = getNumInputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                num = 0;
            else
                num = 1;
            end
        end
        
        function num = getNumOutputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                num = 1 + obj.OutputStatus;
            else
                num = double(obj.OutputStatus);
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = obj.SlaveDataType;
                if obj.OutputStatus
                    varargout{2} = 'uint8';
                end
            else
                if obj.OutputStatus
                    varargout{1} = 'uint8';
                end
            end            
        end
        
        function varargout = getOutputSizeImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = [double(obj.DataLength) 1];
                if obj.OutputStatus
                    varargout{2} = [1 1];
                end
            else
                if obj.OutputStatus
                    varargout{1} = [1 1];
                end
            end
        end
        
        % Names of System block input ports
        function varargout = getInputNamesImpl(obj)
            if 1 == getNumInputsImpl(obj)
                varargout{1} = 'Data';
            end
        end
        
        % Names of System block output ports
        function varargout = getOutputNamesImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = 'Data';
                if obj.OutputStatus
                    varargout{2} = 'Status';
                end
            else
                if obj.OutputStatus
                    varargout{1} = 'Status';
                end
            end            
        end
        
        
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = true;
            end
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = false;
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            % I2C base property list
            [~, PropertyListOut] = matlabshared.svd.I2C.getPropertyGroupsImpl;
            
            % Block property list
            %Direction Direction
            DirectionProp = matlab.system.display.internal.Property('Direction', 'Description', 'svd:svd:DirectionPrompt');
            %RegisterAddressMode Enable register access
            RegisterAddressModeProp = matlab.system.display.internal.Property('RegisterAddressMode', 'Description', 'svd:svd:RegisterAccessPrompt');
            %RegisterAddress Slave register address
            RegisterAddressProp = matlab.system.display.internal.Property('RegisterAddress', 'Description', 'svd:svd:SlaveRegisterAddressPrompt');
            %SlaveDataType Data type
            SlaveDataTypeProp = matlab.system.display.internal.Property('SlaveDataType', 'Description', 'svd:svd:DataTypePrompt');
            %DataLength Data size (N)
            DataLengthProp = matlab.system.display.internal.Property('DataLength', 'Description', 'svd:svd:DataSizePrompt');
            %NoAck Send NACK at the end of data transfer
            NoAckProp = matlab.system.display.internal.Property('NoAck', 'Description', 'svd:svd:SendNACKPrompt');
            %RepeatedStart Remove stop bit at the end of data transfer
            RepeatedStartProp = matlab.system.display.internal.Property('RepeatedStart', 'Description', 'svd:svd:RemoveStopBitPrompt');
            %OutputStatus Output error status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputErrorStatusPrompt');
            
            
            % Property list
            PropertyListOut{end+1} = DirectionProp;
            PropertyListOut{end+1} = RegisterAddressModeProp;
            PropertyListOut{end+1} = RegisterAddressProp;
            PropertyListOut{end+1} = SlaveDataTypeProp;
            PropertyListOut{end+1} = DataLengthProp;
            PropertyListOut{end+1} = NoAckProp;
            PropertyListOut{end+1} = RepeatedStartProp;
            PropertyListOut{end+1} = OutputStatusProp;

            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;

            % Return property list if required
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
