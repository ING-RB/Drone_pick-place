classdef I2C < matlab.System
    % Interfaces to access I2C bus
    %
    % Type <a href="matlab:methods('matlabshared.svd.I2C')">methods('matlabshared.svd.I2C')</a> for a list of methods of the I2C object.
    %
    % Type <a href="matlab:properties('matlabshared.svd.I2C')">properties('matlabshared.svd.I2C')</a> for a list of properties of the I2C object.
    
    %#codegen
    %#ok<*EMCA>
    %#ok<*MCSUP>
    
    % Copyright 2015-2021 The MathWorks, Inc.
    
    % Hardware object
    properties (Hidden)
        Hw = [];
    end
    
    properties (Hidden,Nontunable)
        
     %handle to deploy and connect to IO server   
     DeployAndConnectHandle
     
     %i2cioClient
     i2cIOClient

     %variable to store Connected IO status
     IsIOEnable = false;

    end 
    
    properties (Abstract,Nontunable)
        %I2CModule I2C module
        I2CModule;
    end
    
    % Public, tunable properties.
    properties (Nontunable)
        %Mode Mode
        Mode = 'Master';
        %SlaveAddress Slave address
        SlaveAddress = 10;
        %SlaveByteOrder Slave byte order
        SlaveByteOrder = 'BigEndian';
    end
    
    
    properties (Constant, Hidden)
        ModeSet = matlab.system.StringSet({'Master','Slave'});
        SlaveByteOrderSet = matlab.system.StringSet({'BigEndian','LittleEndian'});
    end
    
    properties (Dependent, Access=protected)
        ModeEnum
        SlaveByteOrderEnum
    end
    
    properties (Hidden, SetAccess=private, GetAccess=public)
        %BusSpeed Bus speed (in Hz)
        BusSpeed = 100000;
    end
    
    properties (Hidden)
        DefaultAddessMode = 7;
        DefaultMaximumBusSpeedInHz = 400000; %Hz
    end

    properties (Access = protected)
        MW_I2C_HANDLE;
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = I2C(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.BusSpeed(obj, value)
            coder.extrinsic('error');
            coder.extrinsic('message');
            validateattributes(value,{'numeric'}, {'nonnegative','scalar','finite','nonnan','nonempty'}, '', 'Bus speed (in Hz)');
            
            if ~isempty(obj.Hw)
                if value > getI2CMaximumBusSpeedInHz(obj.Hw, obj.I2CModule)
                    error(message('svd:svd:AllowedI2CBusSpeed', getI2CMaximumBusSpeedInHz(obj.Hw, obj.I2CModule)));
                end
            else
                if value > obj.DefaultMaximumBusSpeedInHz
                    error(message('svd:svd:AllowedI2CBusSpeed', obj.DefaultMaximumBusSpeedInHz));
                end
            end
            
            obj.BusSpeed = uint32(value);
        end
        
        function set.SlaveAddress(obj, value)
            validateattributes(value,{'numeric'}, {'nonnegative','scalar','integer','finite','nonnan','nonempty'}, '', 'Slave address');
            
            if ~isempty(obj.Hw)
                if ~isempty(obj.Hw)
                    AddressMode = getI2CMaxAllowedAddressBits(obj.Hw, obj.I2CModule);
                else
                    % Default only 7-bits is supported
                    AddressMode = obj.DefaultAddessMode;
                end
                
                if ~ismember(AddressMode,[7 10])
                    error(message('svd:svd:AllowedI2CAddressingModes'));
                elseif value > ((2^AddressMode) - 1)
                    error(message('svd:svd:MaximumAllowedI2CSlaves', (2^AddressMode-1)));
                end
            elseif (value >= 1024)
                error(message('svd:svd:MaximumAllowedI2CSlaves', (2^10-1)));
            end
            
            obj.SlaveAddress = uint32(value);
        end
        
        function ret = get.ModeEnum(obj)
            if isequal(obj.Mode,'Master')
                ret = SVDTypes.MW_Master;
            else
                ret = SVDTypes.MW_Slave;
            end
        end
        
        function ret = get.SlaveByteOrderEnum(obj)
            if isequal(obj.SlaveByteOrder,'BigEndian')
                ret = true;
            else
                ret = false;
            end
        end
    end
    
    %% I2C formal functions
    methods
        % Initialize the I2C device
        function open(obj, varargin)
            
            if ~coder.target('MATLAB')
                % Init I2C device
                coder.cinclude('MW_I2C.h');
                obj.MW_I2C_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                    ModeType = coder.opaque('MW_I2C_Mode_Type','MW_I2C_MASTER','HeaderFile','MW_I2C.h');
                else
                    ModeType = coder.opaque('MW_I2C_Mode_Type','MW_I2C_Slave','HeaderFile','MW_I2C.h');
                end
                if isnumeric(obj.I2CModule)
                    obj.MW_I2C_HANDLE = coder.ceval('MW_I2C_Open', obj.I2CModule, ModeType);
                else
                    i2cname = coder.opaque('uint32_T', obj.I2CModule);
                    obj.MW_I2C_HANDLE = coder.ceval('MW_I2C_Open', i2cname, ModeType);
                end
            else
                obj.MW_I2C_HANDLE = coder.nullcopy(0);
                % Place simulation setup code her
                    %Simulink IO code
                    obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                    if obj.IsIOEnable
                        %handle to deploy and connect to IO server
                        obj.DeployAndConnectHandle=matlabshared.ioclient.DeployAndConnectHandle;
                        %get a connected IOclient object   
                        obj.DeployAndConnectHandle.getConnectedIOClient();                   
                        obj.i2cIOClient = matlabshared.ioclient.peripherals.I2C;
                        
                        %open I2C bus
                        if isnumeric(obj.I2CModule)
                            i2CModule= uint8(obj.I2CModule);
                        else
                            validateattributes(str2double(obj.I2CModule),{'numeric'},{'nonnegative','integer','scalar','real'},'','I2C module');                            
                            i2CModule= uint8(str2double(obj.I2CModule));
                        end
                        try
                            status=openI2CBus(obj.i2cIOClient, obj.DeployAndConnectHandle.IoProtocol, i2CModule);
                        catch
                            throwAsCaller(MException(message('svd:svd:InvalidModuleReconnect','I2C',string(obj.I2CModule))));
                        end
                        %error when opening I2C bus failed
                        if(status)
                            throwAsCaller(MException(message('svd:svd:ModuleNotFound','I2C',string(obj.I2CModule))));
                        end                       
                        
                    end
            end
            
            if nargin > 1
                % Initialise Bus speed
                setBusSpeed(obj, varargin{1});
            end
        end
        
        % Set the I2C bus speed when I2C is master
        function varargout = setBusSpeed(obj, BusSpeed)
            status = coder.nullcopy(uint8(0));
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                obj.BusSpeed = BusSpeed;
                if ~coder.target('MATLAB')
                    coder.cinclude('MW_I2C.h');
                    % Init Bus speed
                    status = coder.ceval('MW_I2C_SetBusSpeed', obj.MW_I2C_HANDLE, obj.BusSpeed);
                else
                    % Place simulation setup code here                    
                    if obj.IsIOEnable
                        if isnumeric(obj.I2CModule)
                            i2CModule= uint8(obj.I2CModule);
                        else
                            i2CModule= uint8(str2double(obj.I2CModule));
                        end                       
                        status=setI2CFrequency(obj.i2cIOClient, obj.DeployAndConnectHandle.IoProtocol, i2CModule, BusSpeed);                           
                    else
                        %do nothing
                    end

                end
            else
                % Slave cannot generate clock signal on I2C bus.
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Set the address of slave.
        function varargout = setSlaveAddress(obj)
            status = coder.nullcopy(uint8(0));
            if ~coder.target('MATLAB')
                coder.cinclude('MW_I2C.h');
                if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                    % Set slave address
                    status = coder.ceval('MW_I2C_SetSlaveAddress', obj.MW_I2C_HANDLE, obj.SlaveAddress);
                else
                    % Not supported
                end
            else
                % Place simulation code here
                if obj.IsIOEnable
                     if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                         %Not Supported in Simulink IO
                        throwAsCaller(MException(message('svd:svd:I2CSetSlaveNotSupportedIO')));
                     end
                else
                    %do nothing
                end
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Read the data from I2C device
        function [output, varargout] = read(obj, DataLength, DataType, RepeatedStart, NoAck)
            % Default values of NoAck and RepeatedStart
            if nargin < 4
                NoAck = false;
                RepeatedStart = false;
            end
            
            % Validat data length
            validateDataLength(obj, DataLength);
            
            % Get number of bytes in the data type
            NumberOfBytes = matlabshared.svd.I2C.getNumberOfBytes(DataType);
            % Allocate output
            output_raw = coder.nullcopy(uint8(zeros(DataLength*NumberOfBytes, 1)));
            
            status = coder.nullcopy(uint8(0));
            
            if ~coder.target('MATLAB')
                coder.cinclude('MW_I2C.h');
                if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                    status = coder.ceval('MW_I2C_MasterRead', obj.MW_I2C_HANDLE, ...
                        obj.SlaveAddress, ...
                        coder.wref(output_raw), ...
                        uint32(DataLength*NumberOfBytes), ...
                        RepeatedStart,NoAck);
                else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                    status = coder.ceval('MW_I2C_SlaveRead', obj.MW_I2C_HANDLE, ...
                        coder.wref(output_raw), ...
                        uint32(DataLength*NumberOfBytes), ...
                        NoAck);
                end
            else
                % Place simulation code here
                if obj.IsIOEnable
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                        if(RepeatedStart)
                            throwAsCaller(MException(message('svd:svd:I2CStopBitNotSupportedIO')));
                        end
                        if(NoAck)
                            throwAsCaller(MException(message('svd:svd:I2CNACKNotSupportedIO')));
                        end
                        %read DataLength*NumberofBytes amount of data into
                        %output_raw: will be double (no matter what the data type written)
                        % Get number of bytes in the data type
                        NumberOfBytes = matlabshared.svd.I2C.getNumberOfBytes(DataType);
                        nBytes = NumberOfBytes * DataLength; 
                        rawValue = zeros(nBytes,1);
                        count = 1;
                        % 64 bytes is the payload size for ioserver
                        % communication. Excluding header and other
                        % overheads, 40 bytes is the limitation set for
                        % data for each operation
                        payloadByteLimit = 40;
                        
                        if isnumeric(obj.I2CModule)
                            i2CModule= uint8(obj.I2CModule);
                        else
                            i2CModule= uint8(str2double(obj.I2CModule));
                        end
                        % If number of bytes to be read is one, directly
                        % read it
                        if nBytes == 1
                            rawValue = obj.i2cIOClient.rawI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,uint32(nBytes));
                        end
                        % If number of bytes to be read is more than one
                        % then following read pattern is followed                        
                        while count ~= nBytes
                            if ((nBytes-count+1) <= payloadByteLimit)
                                [temp,status] = obj.i2cIOClient.rawI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,uint32(nBytes-count+1));
                                count = nBytes;
                            else
                                [temp,status] = obj.i2cIOClient.rawI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,uint32(payloadByteLimit));
                                count = count + payloadByteLimit;
                            end
                            if (count-length(temp)) == 0
                                rawValue(1:length(temp)) = temp;
                            else
                                rawValue((count-length(temp)):(count-1)) = temp;
                            end                           
                        end
                        output_raw = cast(rawValue, 'uint8');
                        status = cast(status,'uint8');
                    else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                        %Not Supported in Simulink IO
                        throwAsCaller(MException(message('svd:svd:I2CSlaveReadNotSupportedIO')));
                    end
                else
                    %do nothing
                end
            end
            
            if obj.SlaveByteOrderEnum
                 output = matlabshared.svd.ByteOrder.changeByteOrder(output_raw, DataType);
            else
                 % Reform the data to required data type
                 output = matlabshared.svd.ByteOrder.concatenateBytes(output_raw, DataType);
            end
            
            if nargout > 1
                varargout{1} = status;
            end
        end
        
    % Read a register from I2C device using raw read functions
        function [output, varargout] = readRegister(obj, RegisterAddress, DataLength, DataType)
            coder.extrinsic('error');
            coder.extrinsic('message');
            output = coder.nullcopy(cast(zeros(DataLength,1), DataType));
            status=uint8(0);
            if ~coder.target('MATLAB')
                % Validat data length
                validateDataLength(obj, DataLength);
            
                % Validate RegisterAddress
                RegisterAddressLimited = validateRegisterAddress(obj,RegisterAddress);
            
                
                if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                    % Write address to Slave device
                    status = write(obj, RegisterAddressLimited, class(RegisterAddressLimited), true, false);
                    if uint8(0) == status
                        % Read data from the slave device
                        [output, status] = read(obj, DataLength, DataType, false, true);
                    else
                        output = cast(zeros(DataLength,1), DataType);
                    end
                else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                    % No support
                    error(message('svd:svd:RegisterOpNotAllowedFromSlave','I2C','read'));
                end
            else
                % Place simulation code here
                if obj.IsIOEnable
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                        % Get number of bytes in the data type
                        NumberOfBytes = matlabshared.svd.I2C.getNumberOfBytes(DataType);
                        nBytes = NumberOfBytes * DataLength;   
                        rawValue = zeros(nBytes,1);
                        count = 1;
                        % 64 bytes is the payload size for ioserver
                        % communication. Excluding header and other
                        % overheads, 40 bytes is the limitation set for
                        % data for each operation
                        payloadByteLimit = 40;
                        if isnumeric(obj.I2CModule)
                            i2CModule= uint8(obj.I2CModule);
                        else
                            i2CModule= uint8(str2double(obj.I2CModule));
                        end
                        
                        % If number of bytes to be read is one, directly
                        % read it
                        if nBytes == 1
                            rawValue = obj.i2cIOClient.registerI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,RegisterAddress,uint32(nBytes));
                        end
                        % If number of bytes to be read is more than one
                        % then following read pattern is followed
                        while count ~= nBytes
                            if ((nBytes-count+1) <= payloadByteLimit)
                                [temp,status] = obj.i2cIOClient.registerI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,RegisterAddress,uint32(nBytes-count+1));
                                count = nBytes;
                            else
                                [temp,status] = obj.i2cIOClient.registerI2CRead(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,RegisterAddress,uint32(payloadByteLimit));
                                count = count + payloadByteLimit;
                                RegisterAddress = RegisterAddress + payloadByteLimit;
                            end
                            if (count-length(temp)) == 0
                                rawValue(1:length(temp)) = temp;
                            else
                                rawValue((count-length(temp)):(count-1)) = temp;
                            end
                        end
                        output_raw = cast(rawValue, 'uint8');
                        status = cast(status,'uint8');
                        
                        if obj.SlaveByteOrderEnum 
                            output = matlabshared.svd.ByteOrder.changeByteOrder(output_raw, DataType);
                        else
                            % Reform the data to required data type
                            output = matlabshared.svd.ByteOrder.concatenateBytes(output_raw, DataType);
                        end
                    else%if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                        %not supported
                        error(message('svd:svd:RegisterOpNotAllowedFromSlave','I2C','read'));                       
                    end
                else
                    %do nothing
                end
                
            end
            
     
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        % Transmit or write to I2C device
        function varargout = write(obj, Data, DataType, RepeatedStart, NoAck)
            % Default values of NoAck and RepeatedStart
            if nargin < 4
                NoAck = false;
                RepeatedStart = false;
            end
            
            if isequal(class(Data),DataType)
                CastedData = Data;
            else
                CastedData = cast(Data, DataType);
            end
            DataLength = numel(CastedData) * matlabshared.svd.I2C.getNumberOfBytes(DataType);
            if obj.SlaveByteOrderEnum
                SwappedDataBytes = matlabshared.svd.ByteOrder.getSwappedBytes(CastedData);
            else
                SwappedDataBytes = matlabshared.svd.ByteOrder.concatenateBytes(CastedData, 'uint8');
            end
            
            status = coder.nullcopy(uint8(0));
            
            if ~coder.target('MATLAB')
                % Write to I2C device
                coder.cinclude('MW_I2C.h');
                if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                    status = coder.ceval('MW_I2C_MasterWrite', obj.MW_I2C_HANDLE, ...
                        obj.SlaveAddress, ...
                        coder.rref(SwappedDataBytes), ...
                        uint32(DataLength), ...
                        RepeatedStart, NoAck);
                else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                    status = coder.ceval('MW_I2C_SlaveWrite', obj.MW_I2C_HANDLE, ...
                        coder.rref(SwappedDataBytes), ...
                        uint32(DataLength), ...
                        NoAck);
                end
            else
                % Place simulation code here
                if obj.IsIOEnable
                    % Place simulation code here
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                        if(RepeatedStart)
                            throwAsCaller(MException(message('svd:svd:I2CStopBitNotSupportedIO')));
                        end
                        if(NoAck)
                            throwAsCaller(MException(message('svd:svd:I2CNACKNotSupportedIO')));
                        end
                        
                        if isnumeric(obj.I2CModule)
                            i2CModule= uint8(obj.I2CModule);
                        else
                            i2CModule= uint8(str2double(obj.I2CModule));
                        end   
                        
                        if iscolumn(SwappedDataBytes)
                            SwappedDataBytes=SwappedDataBytes';
                        end
                         count = 1;
                         % 64 bytes is the payload size for ioserver
                         % communication. Excluding header and other
                         % overheads, 40 bytes is the limitation set for
                         % data for each operation
                         payloadByteLimit = 40;
                        % If number of bytes to be written is one, directly
                        % write it
                        if length(SwappedDataBytes) == 1
                            status = obj.i2cIOClient.rawI2CWrite(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,uint32(SwappedDataBytes));
                        end
                        % If number of bytes to be written is more than one
                        % then following write pattern is followed                         
                         while count ~= length(SwappedDataBytes)
                            if((length(SwappedDataBytes)-count+1) <= payloadByteLimit)
                                data = SwappedDataBytes(count:length(SwappedDataBytes));
                                count = length(SwappedDataBytes);
                            else
                                data = SwappedDataBytes(count:(count+payloadByteLimit-1));
                                count = count + payloadByteLimit;
                            end
                            status = obj.i2cIOClient.rawI2CWrite(obj.DeployAndConnectHandle.IoProtocol,i2CModule,obj.SlaveAddress,data);                                                                                        
                            if status == 1
                                 break;
                            end
                         end
                       status = cast(status,'uint8');
                    else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                        %not supported in Simulink IO
                        throwAsCaller(MException(message('svd:svd:I2CSlaveWriteNotSupportedIO')));  
                    end
                else
                    %do nothing
                end
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Transmit or write to I2C device using raw write
        function varargout = writeRegister(obj, RegisterAddress, Data, DataType)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            % Validate RegisterAddress
            RegisterAddressLimited = validateRegisterAddress(obj,RegisterAddress);
            
            % Typecast the data to required slave data type
            if isequal(class(Data),DataType)
                CastedData = Data;
            else
                CastedData = cast(Data, DataType);
            end
            
            if obj.SlaveByteOrderEnum
                SwappedDataBytes = matlabshared.svd.ByteOrder.getSwappedBytes(CastedData);
            else
                SwappedDataBytes = matlabshared.svd.ByteOrder.concatenateBytes(CastedData, 'uint8');
            end
            
            % Concatenate RegisterAddress and Data to write to slave
            % device.
            addr_size = size(RegisterAddressLimited);
            data_size = size(SwappedDataBytes);
            
            if (addr_size(1) == data_size(1)) && (addr_size(1) == 1)
                SwappedDataBytes = [RegisterAddressLimited SwappedDataBytes];
            else
                SwappedDataBytes = [RegisterAddressLimited'; SwappedDataBytes];
            end
            
            status = coder.nullcopy(uint8(0)); %#ok<NASGU>
            
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                status = write(obj, SwappedDataBytes, 'uint8',...
                    false, false);
            else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                % Not supported
                error(message('svd:svd:RegisterOpNotAllowedFromSlave','write','I2C'));
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Get the status of I2C
        function status = getStatus(obj)
            status = coder.nullcopy(uint8(0));
            if ~coder.target('MATLAB')
                % Init PWM
                coder.cinclude('MW_I2C.h');
                status = coder.ceval('MW_I2C_GetStatus', obj.MW_I2C_HANDLE);
            else
                % Place simulation setup code here
            end
        end
        
        % Release the I2C module
        function close(obj)
            if ~coder.target('MATLAB')
                % Init PWM
                coder.cinclude('MW_I2C.h');
                coder.ceval('MW_I2C_Close', obj.MW_I2C_HANDLE);
            else
                % Place simulation code here
                if obj.IsIOEnable
                    if isnumeric(obj.I2CModule)
                        i2CModule= uint8(obj.I2CModule);
                    else
                        i2CModule= uint8(str2double(obj.I2CModule));
                    end                     
                    closeI2CBus(obj.i2cIOClient, obj.DeployAndConnectHandle.IoProtocol, i2CModule);
                    obj.DeployAndConnectHandle.deleteConnectedIOClient;
                else
                    %do nothing
                end
            end
        end
    end
    
    methods (Static)
        function allowedDataType(DataType)
            validatestring(DataType,{'int8','uint8','int16','uint16','int32','uint32','int64','uint64','single','double'}, '', 'Data type');
        end
        
        function NumberOfBytes = getNumberOfBytes(DataType)
            matlabshared.svd.I2C.allowedDataType(DataType);
            switch (DataType)
                case {'int8','uint8'}
                    NumberOfBytes = 1;
                case {'int16','uint16'}
                    NumberOfBytes = 2;
                case {'int32','uint32','single'}
                    NumberOfBytes = 4;
                case {'int64','uint64','double'}
                    NumberOfBytes = 8;
                otherwise
                    error('Invalid datatype');
            end
        end
    end
    
    methods (Access=protected)
        function RegisterAddressLimited = validateRegisterAddress(~, RegisterAddress)
            validateattributes(RegisterAddress,{'numeric'}, {'nonnegative','integer','vector','finite','nonnan','nonempty','<=',255}, '', 'Slave register address');

            RegisterAddressLimited = uint8(RegisterAddress);
        end
        
        function DataLength = validateDataLength(~, DataLength)
            validateattributes(DataLength,{'numeric'}, {'nonnegative','scalar','integer','finite','nonnan','nonempty'}, '', 'Data length');
        end
    end
    
    % System object methods
    methods (Access = protected)
        function varargout = stepImpl(~,varargin)
            varargout{1} = 0;
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
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
           %I2CModule I2C module
            I2CModuleProp = matlab.system.display.internal.Property('I2CModule', 'Description', 'svd:svd:I2CModulePrompt');
            %Mode Mode
            ModeProp = matlab.system.display.internal.Property('Mode', 'Description', 'svd:svd:I2CModePrompt');
            %SlaveAddress Slave address
            SlaveAddressProp = matlab.system.display.internal.Property('SlaveAddress', 'Description', 'svd:svd:SlaveAddressPrompt');
            %SlaveByteOrder Slave byte order
            SlaveByteOrderProp = matlab.system.display.internal.Property('SlaveByteOrder', 'Description', 'svd:svd:SlaveByteOrderPrompt');

            
            % Property list
            PropertyListOut = {I2CModuleProp, ModeProp, SlaveAddressProp, SlaveByteOrderProp};

            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;

            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
