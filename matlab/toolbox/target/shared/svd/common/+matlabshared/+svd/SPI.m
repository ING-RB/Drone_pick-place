classdef (StrictDefaults)SPI < matlabshared.svd.DigitalWrite                           
    % Interfaces to access SPI bus
    %
    % Type <a href="matlab:methods('matlabshared.svd.SPI')">methods('matlabshared.svd.SPI')</a> for a list of methods of the raspi object.
    %
    % Type <a href="matlab:properties('matlabshared.svd.SPI')">properties('matlabshared.svd.SPI')</a> for a list of properties of the raspi object.
    
    %#codegen
    %#ok<*EMCA>
    
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    properties (Abstract,Nontunable)
        %SPIModule SPI module
        SPIModule;
    end
    
     properties (Hidden,Nontunable)
        %SPIIOClient
        SPIIOClient
     end    
       
    % Public, tunable properties.
    properties (Nontunable)
        %Mode Mode
        Mode = 'Master';
        %FirstBitToTransfer First bit to transfer
            % MSB - Most significant bit
            % LSB - Least significant bit
        FirstBitToTransfer = 'Most significant bit (MSB)';
        %ClockMode Mode (Clock polarity and phase)
            % 0 - Clock polarity - active state is 1 and idle state is 0
            % 0 - Clock phase - Data are latched on the occurrence of the first clock transition
            % 0 - Clock polarity - active state is 1 and idle state is 0
            % 1 - Clock phase - Data are latched on the occurrence of the second clock transition
            % 1 - Clock polarity - active state is 0 and idle state is 1
            % 0 - Clock phase - Data are latched on the occurrence of the first clock transition
            % 1 - Clock polarity - active state is 0 and idle state is 1
            % 1 - Clock phase - Data are latched on the occurrence of the second clock transition
        ClockMode = '0';
        %UseCustomSSPin Slave select calling method
        UseCustomSSPin = 'Explicit GPIO calls';
        %ActiveLowSSPin Slave select pin polarity
        ActiveLowSSPin = 'Active low';
    end
    
    
    properties (Constant, Hidden)
        ModeSet = matlab.system.StringSet({'Master','Slave'});
        ActiveLowSSPinSet = matlab.system.StringSet({'Active low','Active high'});
        ClockModeSet = matlab.system.StringSet({'0','1','2','3'});
        UseCustomSSPinSet = matlab.system.StringSet({'Explicit GPIO calls', 'Provided by the SPI peripheral'});
        FirstBitToTransferSet = matlab.system.StringSet({'Most significant bit (MSB)','Least significant bit (LSB)'});
    end
    
    properties (Access = private, Nontunable)
        % TargetBitsPerFrame Default Bits per frame - Target transmits or receives data in
        % chunks of 8 bits
        TargetBitsPerFrame = uint8(8);
    end
    
    properties (Dependent, Access=protected)
        ModeEnum
        ActiveLowSSPinEnum
        ClockModeEnum
        SlaveByteOrderEnum
        FirstBitToTransferEnum
        UseCustomSSPinEnum
    end
    
    properties (Nontunable)
        %BusSpeed Bus speed (in Hz)
        BusSpeed = uint32(1000000);
    end

    properties (Access = protected)
        MW_SPI_HANDLE;
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = SPI(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function ret = get.FirstBitToTransferEnum(obj)
            switch obj.FirstBitToTransfer
                case 'Least significant bit (LSB)'
                    ret = false;
                otherwise
                    ret = true;
            end
        end
        
        function set.FirstBitToTransferEnum(obj, value)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            validateattributes(value, {'numeric','logical'}, ...
                        {'scalar','binary','finite','nonnan','nonempty'}, ...
                        '', ...
                        'FirstBitToTransfer');
            switch logical(value)
                case 0
                    obj.FirstBitToTransfer = 'Least significant bit (LSB)';
                otherwise
                    obj.FirstBitToTransfer = 'Most significant bit (LSB)';
            end
        end
        
        function set.BusSpeed(obj, value)
            coder.extrinsic('error');
            coder.extrinsic('message');
            validateattributes(value, {'numeric'}, {'nonnegative','scalar','real','finite','nonnan','nonempty'}, '', 'Bus speed (in Hz)');
            
            if coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid')
                if ~isempty(obj.Hw)
                    if value > getSPIMaximumBusSpeedInHz(obj.Hw, obj.SPIModule) %#ok<MCSUP>
                        error(message('svd:svd:AllowedBusSpeed', 'SPI', getSPIMaximumBusSpeedInHz(obj.Hw, obj.SPIModule))); %#ok<MCSUP>
                    end
                end
            end
            
            obj.BusSpeed = uint32(value);
        end
        
        function ret = get.BusSpeed(obj)
            ret = uint32(obj.BusSpeed);
        end
        
        function ret = get.ModeEnum(obj)
            if isequal(obj.Mode,'Master')
                ret = SVDTypes.MW_Master;
            else
                ret = SVDTypes.MW_Slave;
            end
        end
        
        function ret = get.ClockModeEnum(obj)
            if isequal(obj.ClockMode,'0')
                ret = uint8(0);
            elseif isequal(obj.ClockMode,'1')
                ret = uint8(1);
            elseif isequal(obj.ClockMode,'2')
                ret = uint8(2);
            elseif isequal(obj.ClockMode,'3')
                ret = uint8(3);
            else
                ret = uint8(0);
            end
        end
        
        function ret = get.ActiveLowSSPinEnum(obj)
            if isequal(obj.ActiveLowSSPin, 'Active low')
                ret = true;
            else
                ret = false;
            end
        end
        
        function set.ClockModeEnum(obj, value)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            validateattributes(value, {'numeric'}, ...
                        {'scalar','integer','nonnegative','finite','nonnan','nonempty','<=',3}, ...
                        '', ...
                        'ClockMode')
            switch value
                case 0
                    obj.ClockMode = '0';
                case 1
                    obj.ClockMode = '1';
                case 2
                    obj.ClockMode = '2';
                case 3
                    obj.ClockMode = '3';
            end
        end
        
        % true if SlaveByteOrder is BigEndian
        % false if SlaveByteOrder is LittleEndian
        function ret = get.SlaveByteOrderEnum(obj)
            if isequal(obj.SlaveByteOrder,'BigEndian')
                ret = true;
            else
                ret = false;
            end
        end
        
        function set.TargetBitsPerFrame(obj, value)
            validateattributes(value, {'numeric'}, ...
                        {'scalar','integer','nonnegative'}, ...
                        '', ...
                        'TargetBitsPerFrame');
            obj.TargetBitsPerFrame = uint8(value);
        end
        
        function ret = get.TargetBitsPerFrame(obj)
            ret = obj.TargetBitsPerFrame;
        end

        function ret = get.UseCustomSSPinEnum(obj)
            if isequal(obj.UseCustomSSPin, 'Explicit GPIO calls')
                ret = true;
            else
                ret = false;
            end
        end
    end
    
    %% SPI formal functions
    methods
        % Initialize the SPI device
        function open(obj)
            % Intialize the GPIO if the mode is Master
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                if obj.UseCustomSSPinEnum
                    % Initialize the GPIO to output
                    open@matlabshared.svd.DigitalWrite(obj);
                    % Deselect the slave
                    writeDigitalPin(obj, obj.ActiveLowSSPinEnum);
                end
            end
            
            % Target frame size interms of bits
%             if isempty(obj.Hw)
%                 obj.TargetBitsPerFrame = uint8(8);
%             else
%                 obj.TargetBitsPerFrame = uint8(getSPIShiftRegisterPrecision(obj.Hw, obj.SPIModule));
%             end

            % Initialise SPI data frame size and mode
            if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                % Init SPI device
                coder.cinclude('MW_SPI.h');
                obj.MW_SPI_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                % Intialise SPI
                    % SPI ID
                if isnumeric(obj.SPIModule)
                    SPINameLoc = obj.SPIModule;
                else
                    SPINameLoc = coder.opaque('uint32_T', obj.SPIModule);
                end
                    % Slave select pin
                if isnumeric(obj.Pin)
                    SSPinNameLoc = obj.Pin;
                else
                    SSPinNameLoc = coder.opaque('uint32_T', obj.Pin);
                end
                    % MOSI,MISO and SCK Pins
                if isempty(obj.Hw)
                    % MOSI, MISO and SCK pins not defined
                    SPIPinsLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    MOSIPinLoc = SPIPinsLoc;
                    MISOPinLoc = SPIPinsLoc;
                    SCKPinLoc = SPIPinsLoc;
                else
                    % MOSI
                    MOSIPin = getSPIMosiPin(obj.Hw, obj.SPIModule);
                    if isempty(MOSIPin)
                        MOSIPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(MOSIPin)
                            MOSIPinLoc = uint32(MOSIPin);
                        else
                            MOSIPinLoc = coder.opaque('uint32_T', MOSIPin);
                        end
                    end
                    % MISO
                    MISOPin = getSPIMisoPin(obj.Hw, obj.SPIModule);
                    if isempty(MISOPin)
                        MISOPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(MISOPin)
                            MISOPinLoc = uint32(MISOPin);
                        else
                            MISOPinLoc = coder.opaque('uint32_T', MISOPin);
                        end
                    end
                    % SCK
                    SCKPin = getSPIClockPin(obj.Hw, obj.SPIModule);
                    if isempty(SCKPin)
                        SCKPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(SCKPin)
                            SCKPinLoc = uint32(SCKPin);
                        else
                            SCKPinLoc = coder.opaque('uint32_T', SCKPin);
                        end
                    end
                end
                obj.MW_SPI_HANDLE = coder.ceval('MW_SPI_Open',SPINameLoc,...
                    MOSIPinLoc,MISOPinLoc,SCKPinLoc,...
                    SSPinNameLoc, obj.ActiveLowSSPinEnum,obj.ModeEnum);
            elseif coder.target('RtwForRapid')
            else
                obj.MW_SPI_HANDLE = coder.nullcopy(0);               
                %Simulink IO code
                obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                if obj.IsIOEnable && coder.target('MATLAB')
                    %handle to deploy and connect to IO server                       
                    obj.DeployAndConnectHandle=matlabshared.ioclient.DeployAndConnectHandle;
                    %get a connected IOclient object
                    obj.DeployAndConnectHandle.getConnectedIOClient();

                    obj.SPIIOClient = matlabshared.ioclient.peripherals.SPI;
                    
                    % MOSI,MISO and SCK Pins
                    if isempty(obj.Hw)
                        % MOSI, MISO and SCK pins not defined
                        SPIPinsLoc = intmax('uint32'); % 'MW_UNDEFINED_VALUE'
                        MOSIPinLoc = SPIPinsLoc;
                        MISOPinLoc = SPIPinsLoc;
                        SCKPinLoc = SPIPinsLoc;
                    else
                        % MOSI
                        MOSIPin = getSPIMosiPin(obj.Hw, obj.SPIModule);
                        if isempty(MOSIPin)
                            MOSIPinLoc = intmax('uint32');% 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(MOSIPin)
                                MOSIPinLoc = uint32(MOSIPin);
                            else
                                MOSIPinLoc = uint32(str2double(MOSIPin));
                            end
                        end
                        % MISO
                        MISOPin = getSPIMisoPin(obj.Hw, obj.SPIModule);
                        if isempty(MISOPin)
                            MISOPinLoc = intmax('uint32');% 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(MISOPin)
                                MISOPinLoc = uint32(MISOPin);
                            else
                                MISOPinLoc = uint32(str2double(MISOPin));
                            end
                        end
                        % SCK
                        SCKPin = getSPIClockPin(obj.Hw, obj.SPIModule);
                        if isempty(SCKPin)
                            SCKPinLoc = intmax('uint32'); % 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(SCKPin)
                                SCKPinLoc = uint32(SCKPin);
                            else
                                SCKPinLoc = uint32(str2double(SCKPin));
                            end
                        end
                    end
                    
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)                        
                        if obj.ActiveLowSSPinEnum
                            CSPinActive='low';
                        else
                            CSPinActive='high';
                        end
                        if isnumeric(obj.SPIModule)
                            spiModule= uint8(obj.SPIModule);
                        else
                            validateattributes(str2double(obj.SPIModule),{'numeric'},{'nonnegative','integer','scalar','real'},'','SPI module');
                            spiModule= uint8(str2double(obj.SPIModule));
                        end
                        try
                            if obj.UseCustomSSPinEnum
                                status = openSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule, MOSIPinLoc, MISOPinLoc, SCKPinLoc, obj.PinInternalIO,'isCSPinActiveLow',CSPinActive);
                            else
                                status = openSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule, MOSIPinLoc, MISOPinLoc, SCKPinLoc, obj.Pin,'isCSPinActiveLow',CSPinActive);
                            end
                        catch
                            throwAsCaller(MException(message('svd:svd:InvalidModuleReconnect','SPI',string(obj.SPIModule))));
                        end
                        %error when opening SPI bus failed
                        if(status)
                            throwAsCaller(MException(message('svd:svd:ModuleNotFound','SPI',string(obj.SPIModule))));
                        end
                    else
                        %not supported
                    end
                end
            end
            
            % Set bus speed
            setBusSpeed(obj);      
        end
        
        % Set SPI transmission format
        function varargout = setFormat(obj, ClockMode, MsbFirst)
            if nargin > 1
                narginchk(3,3);
            else
                narginchk(1,1);
            end
            
            if nargin > 1
                obj.ClockModeEnum = ClockMode;
                obj.FirstBitToTransferEnum = MsbFirst;
            end
            
            status = coder.nullcopy(uint8(0));
            if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                coder.cinclude('MW_SPI.h');
                % ClockMode value
                ClockModeValue = coder.const(@obj.getSPIModeTypeValue, obj.ClockMode);
                ClockModeValue = coder.opaque('MW_SPI_Mode_type', ClockModeValue);
                % Target First bit to transfer
                MsbFirstTransferLoc = coder.const(@obj.getSPIFirstTransferBit, obj.FirstBitToTransferEnum);
                MsbFirstTransferLoc = coder.opaque('MW_SPI_FirstBitTransfer_Type', MsbFirstTransferLoc);
                % Change SPI mode
                status = coder.ceval('MW_SPI_SetFormat', obj.MW_SPI_HANDLE, obj.TargetBitsPerFrame, ClockModeValue, MsbFirstTransferLoc);
            else
                if obj.IsIOEnable
                % Place simulation setup code here
                    if obj.FirstBitToTransferEnum
                        bitOrder='msbfirst';
                    else
                        bitOrder='lsbfirst';
                    end
                    if isnumeric(obj.SPIModule)
                        spiModule= uint8(obj.SPIModule);
                    else
                        spiModule= uint8(str2double(obj.SPIModule));
                    end                    
                    status = setFormatSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule, obj.TargetBitsPerFrame, obj.ClockModeEnum, bitOrder);
                else
                    % Do Nothing for the Normal Simulation Mode
                end
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Set the SPI bus speed when SPI is master
        function varargout = setBusSpeed(obj, BusSpeed)
            narginchk(1,2);
            
            status = coder.nullcopy(uint8(0));
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                % Set the input bus speed
                if nargin > 1
                    BusSpeedHw = uint32(BusSpeed);
                    % Set the bus speed from the hardware
                else
                    if ~isempty(obj.Hw) && ~getBusSpeedParameterVisibility(obj.Hw, obj.SPIModule)
                        BusSpeedHw = uint32(getSPIBusSpeedInHz(obj.Hw, obj.SPIModule));
                        % Set the default Bus speed
                    else
                        BusSpeedHw = obj.BusSpeed;
                    end
                end
            
			if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                    coder.cinclude('MW_SPI.h');
                    % Init Bus speed
                    status = coder.ceval('MW_SPI_SetBusSpeed', obj.MW_SPI_HANDLE, BusSpeedHw);
                else
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        if isnumeric(obj.SPIModule)
                            spiModule= uint8(obj.SPIModule);
                        else
                            spiModule= uint8(str2double(obj.SPIModule));
                        end                         
                        status = setBusSpeedSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule, BusSpeedHw);
                    else
                    % Do Nothing for the Normal Simulation Mode
                    end
                end
            else
                % Slave cannot generate clock signal on SPI bus.
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Write and Read the data from SPI slave device
        function [rdData, varargout] = writeRead(obj, wrData, precision)
            % Assert for allowed precisions
            obj.allowedDataType(precision);

            validateattributes(wrData,{'numeric'},{'vector'},'','Data');
            datasize = size(wrData);
            % Initialize output
            if isequal(datasize(1), 1)
                rdDataRaw = coder.nullcopy(cast(zeros(1, numel(wrData)*matlabshared.svd.ByteOrder.getNumberOfBytes(precision)),'uint8'));
            else
                rdDataRaw = coder.nullcopy(cast(zeros(numel(wrData)*matlabshared.svd.ByteOrder.getNumberOfBytes(precision), 1),'uint8'));
            end

            % Cast the wrData to required precision
            if isequal(class(wrData), precision)
                CastedData = wrData;
            else
                CastedData = cast(wrData, precision);
            end
            
            % Transform data according before transmitting
                % Most significant bit transfer first
            if obj.FirstBitToTransferEnum
                % Endian conversion
                wrDataRaw = matlabshared.svd.ByteOrder.getSwappedBytes(CastedData);
            else
                % form bytes
                wrDataRaw = matlabshared.svd.ByteOrder.concatenateBytes(CastedData,'uint8');
            end
            
            % Configures the slave select pin available in the SPI peripheral.
            % This function doesn't do anything if slave select pin used is
            % custom pin
            setSlaveSelect(obj);
            
            % Set SPI transmission format
                % Set ClockMode, Bits/Frame and FirstBitToTransfer from the hardware
            status = setFormat(obj);
            
            if (~status)
                if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                    %coder.cinclude('MW_SPI.h');
                    
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                        % drive Slave select pin low or high to select the
                        % slave using digital write pin
                        if obj.UseCustomSSPinEnum
                            writeDigitalPin(obj, ~obj.ActiveLowSSPinEnum);
                        end
                        
                        status = coder.ceval('MW_SPI_MasterWriteRead_8bits', obj.MW_SPI_HANDLE, ...
                            coder.rref(wrDataRaw), coder.wref(rdDataRaw), ...
                            uint32(numel(wrDataRaw)));

                        % Release the slave
                        if obj.UseCustomSSPinEnum
                            writeDigitalPin(obj, obj.ActiveLowSSPinEnum);
                        end
                    else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                        status = coder.ceval('MW_SPI_SlaveWriteRead_8bits', obj.MW_SPI_HANDLE, ...
                            coder.rref(wrDataRaw), coder.wref(rdDataRaw), ...
                            uint32(numel(wrDataRaw)));
                    end
                else
                    if obj.IsIOEnable
                        % Place simulation code here
                        
                        % drive Slave select pin low or high to select the
                        % slave using digital write pin
                        if obj.UseCustomSSPinEnum
                            writeDigitalPin(obj, ~obj.ActiveLowSSPinEnum);
                        end
                        
                        if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                            if iscolumn(wrDataRaw)
                                wrDataRaw=wrDataRaw';
                            end
                            if isnumeric(obj.SPIModule)
                                spiModule= uint8(obj.SPIModule);
                            else
                                spiModule= uint8(str2double(obj.SPIModule));
                            end
                            if obj.UseCustomSSPinEnum
                                [rdDataRaw,status]=writeReadSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol,spiModule, obj.PinInternalIO, obj.ActiveLowSSPinEnum, length(wrDataRaw), wrDataRaw);
                            else
                                [rdDataRaw,status]=writeReadSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol,spiModule, obj.Pin, obj.ActiveLowSSPinEnum, length(wrDataRaw), wrDataRaw);
                            end
                                

                        else %if isequal(obj.ModeEnum, SVDTypes.MW_Slave)
                             %Not Supported in Simulink IO
                             throwAsCaller(MException(message('svd:svd:SPISlaveReadWriteNotSupportedIO')));
                        end
                        % Release the slave
                        if obj.UseCustomSSPinEnum
                            writeDigitalPin(obj, obj.ActiveLowSSPinEnum);
                        end
                        rdDataRaw=cast(rdDataRaw, 'uint8');
                    else
                        %do nothing
                    end
                end
            end
            
            % Transform data according before transmitting
                % Most significant bit transfer first
            if obj.FirstBitToTransferEnum
                % Endian conversion
                rdData = matlabshared.svd.ByteOrder.changeByteOrder(rdDataRaw, precision);
            else
                % form bytes
                rdData = matlabshared.svd.ByteOrder.concatenateBytes(rdDataRaw,precision);
            end
            
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        % Configures the slave select pin available in the SPI peripheral.
        % This function doesn't do anything if slave select pin used is
        % custom pin
        function varargout = setSlaveSelect(obj)
            status = coder.nullcopy(uint8(0));
            if ~obj.UseCustomSSPinEnum
                if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                    coder.cinclude('MW_SPI.h');
                    
                    % Slave select pin
                    if isnumeric(obj.Pin)
                        PinNameLoc = uint8(obj.Pin);
                    else
                        PinNameLoc = coder.opaque('uint32_T', obj.Pin);
                    end
                    % Call the function to configure
                    status = coder.ceval('MW_SPI_SetSlaveSelect', obj.MW_SPI_HANDLE, PinNameLoc, obj.ActiveLowSSPinEnum);
                else
                    % Add simulation code here
                end
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Get the status of SPI
        function status = getStatus(obj)
            status = coder.nullcopy(uint8(0));
            if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                % Init PWM
                coder.cinclude('MW_SPI.h');
                status = coder.ceval('MW_SPI_GetStatus', obj.MW_SPI_HANDLE);
            else
                % Place simulation setup code here
            end
        end
        
        % Release the SPI module
        function close(obj)
            if ~(coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid'))
                % DeInit SPI
                coder.cinclude('MW_SPI.h');
                if obj.UseCustomSSPinEnum
                    % DeInit Digital write
                    close@matlabshared.svd.DigitalWrite(obj);
                end
                
                    % Slave select pin
                if isnumeric(obj.Pin)
                    PinNameLoc = obj.Pin;
                else
                    PinNameLoc = coder.opaque('uint32_T', obj.Pin);
                end
                    % MOSI,MISO and SCK Pins
                if isempty(obj.Hw)
                    % MOSI, MISO and SCK pins not defined
                    SPIPinsLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    MOSIPinLoc = SPIPinsLoc;
                    MISOPinLoc = SPIPinsLoc;
                    SCKPinLoc = SPIPinsLoc;
                else
                    % MOSI
                    MOSIPin = getSPIMosiPin(obj.Hw, obj.SPIModule);
                    if isempty(MOSIPin)
                        MOSIPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(MOSIPin)
                            MOSIPinLoc = uint32(MOSIPin);
                        else
                            MOSIPinLoc = coder.opaque('uint32_T', MOSIPin);
                        end
                    end
                    % MISO
                    MISOPin = getSPIMisoPin(obj.Hw, obj.SPIModule);
                    if isempty(MISOPin)
                        MISOPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(MISOPin)
                            MISOPinLoc = uint32(MISOPin);
                        else
                            MISOPinLoc = coder.opaque('uint32_T', MISOPin);
                        end
                    end
                    % SCK
                    SCKPin = getSPIClockPin(obj.Hw, obj.SPIModule);
                    if isempty(SCKPin)
                        SCKPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(SCKPin)
                            SCKPinLoc = uint32(SCKPin);
                        else
                            SCKPinLoc = coder.opaque('uint32_T', SCKPin);
                        end
                    end
                end
                coder.ceval('MW_SPI_Close', obj.MW_SPI_HANDLE, MOSIPinLoc, MISOPinLoc, SCKPinLoc, PinNameLoc);
            else
                if obj.IsIOEnable
                % Place simulation setup code here
                    % MOSI,MISO and SCK Pins
                    if isempty(obj.Hw)
                        % MOSI, MISO and SCK pins not defined
                        SPIPinsLoc = intmax('uint32'); % 'MW_UNDEFINED_VALUE'
                        MOSIPinLoc = SPIPinsLoc;
                        MISOPinLoc = SPIPinsLoc;
                        SCKPinLoc = SPIPinsLoc;
                    else
                        % MOSI
                        MOSIPin = getSPIMosiPin(obj.Hw, obj.SPIModule);
                        if isempty(MOSIPin)
                            MOSIPinLoc = intmax('uint32');% 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(MOSIPin)
                                MOSIPinLoc = uint32(MOSIPin);
                            else
                                MOSIPinLoc = uint32(str2double(MOSIPin));
                            end
                        end
                        % MISO
                        MISOPin = getSPIMisoPin(obj.Hw, obj.SPIModule);
                        if isempty(MISOPin)
                            MISOPinLoc = intmax('uint32');% 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(MISOPin)
                                MISOPinLoc = uint32(MISOPin);
                            else
                                MISOPinLoc = uint32(str2double(MISOPin));
                            end
                        end
                        % SCK
                        SCKPin = getSPIClockPin(obj.Hw, obj.SPIModule);
                        if isempty(SCKPin)
                            SCKPinLoc = intmax('uint32'); % 'MW_UNDEFINED_VALUE'
                        else
                            if isnumeric(SCKPin)
                                SCKPinLoc = uint32(SCKPin);
                            else
                                SCKPinLoc = uint32(str2double(SCKPin));
                            end
                        end
                    end
                    if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                        
                        if isnumeric(obj.SPIModule)
                            spiModule= uint8(obj.SPIModule);
                        else
                            spiModule= uint8(str2double(obj.SPIModule));
                        end
                        
                        if obj.UseCustomSSPinEnum
                            status=closeSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule,MOSIPinLoc, MISOPinLoc, SCKPinLoc, obj.PinInternalIO);
                            obj.dIOClient.unconfigureDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO );
                        else
                            status=closeSPI(obj.SPIIOClient, obj.DeployAndConnectHandle.IoProtocol, spiModule,MOSIPinLoc, MISOPinLoc, SCKPinLoc, obj.Pin);
                        end
                        obj.DeployAndConnectHandle.deleteConnectedIOClient;
                    else
                        %not supported
                    end
                
                else
                    %do nothing
                end
            end
        end
        
        % Write data to SPI slave device
        function [varargout] = writeRegister(obj, RegisterAddress, wrData, precision)
            nargoutchk(0,1);
            
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                % Assert for allowed precisions
                obj.allowedDataType(precision);

                % Validate register address
                obj.validateRegisterAddress(RegisterAddress);
                
                % Cast the wrData to required precision
                if isequal(class(wrData), precision)
                    CastedData = wrData;
                else
                    CastedData = cast(wrData, precision);
                end
                
                % Cast to uint8
                if isequal(class(RegisterAddress), 'uint8')
                    RegisterAddressRaw = RegisterAddress;
                else
                    RegisterAddressRaw = cast(RegisterAddress, 'uint8');
                end
                                
                % Transform data according before transmitting
                    % Most Significant bit transfer first
                if obj.FirstBitToTransferEnum
                    % Endian conversion
                    
                    wrDataRaw = matlabshared.svd.ByteOrder.getSwappedBytes(CastedData);
                else    % Least significant bit transfer first
                    % form bytes
                    wrDataRaw = matlabshared.svd.ByteOrder.concatenateBytes(CastedData,'uint8');
                end
                
                % Concatenate RegisterAddress and Data to write to slave
                % device.
                addr_size = size(RegisterAddressRaw);
                data_size = size(wrDataRaw);
                if (addr_size(1) == data_size(1)) && (data_size(1) == 1)
                    wrDataRaw1 = [RegisterAddressRaw wrDataRaw];
                else
                    wrDataRaw1 = [RegisterAddressRaw'; wrDataRaw];
                end
                
                % Call writeRead function
                [~, status] = writeRead(obj, wrDataRaw1, class(wrDataRaw1));
            else
                % No support
                error(message('svd:svd:RegisterOpNotAllowedFromSlave','SPI','read'));
            end

            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Write and Read the data from SPI slave device
        function [rdData, varargout] = readRegister(obj, RegisterAddress, DataLength, precision)
            nargoutchk(1,2);
            
            if isequal(obj.ModeEnum, SVDTypes.MW_Master)
                % Assert for allowed precisions
                obj.allowedDataType(precision);

                % Validate data length
                obj.validateDataLength(DataLength);

                % Validate register address
                obj.validateRegisterAddress(RegisterAddress);
                
                % Cast to uint8
                if isequal(class(RegisterAddress), 'uint8')
                    RegisterAddressRaw = RegisterAddress;
                else
                    RegisterAddressRaw = cast(RegisterAddress, 'uint8');
                end
                
                % Initialize output
                rdDataRaw = cast(zeros(DataLength*matlabshared.svd.ByteOrder.getNumberOfBytes(precision)+numel(RegisterAddressRaw),1),'uint8');
                for i = 1:numel(RegisterAddressRaw)
                    rdDataRaw(i) = RegisterAddressRaw(i);
                end
                
                % Call SPI writeRead
                [rdDataRaw, status] = writeRead(obj, rdDataRaw, class(rdDataRaw));
                rdDataRaw1 = rdDataRaw(numel(RegisterAddressRaw)+1:end);
                
                % Transform data according before transmitting
                    % Most Significant bit transfer first
                if obj.FirstBitToTransferEnum
                    % Endian conversion
                    rdData = matlabshared.svd.ByteOrder.changeByteOrder(rdDataRaw1, precision);
                else    % Least significant bit transfer first
                    % form bytes
                    rdData = matlabshared.svd.ByteOrder.concatenateBytes(rdDataRaw1,precision);
                end
            else
                % No support
                error(message('svd:svd:RegisterOpNotAllowedFromSlave','SPI','read'));
            end
            
            if nargout > 1
                varargout{1} = status;
            end
        end
    end
    
    methods (Static)
        function allowedDataType(DataType)
            validatestring(DataType,{'int8','uint8','int16','uint16','int32','uint32','single','double'}, '', 'precision');
        end

        function validateRegisterAddress(RegisterAddress)
            % Validate register address
            validateattributes(RegisterAddress,{'numeric'}, {'nonnegative','integer','vector','finite','nonnan','nonempty','<=',255}, '', 'Peripheral register address');
        end

        function validateDataLength(DataLength)
            % Validate Data length
            validateattributes(DataLength,{'numeric'},{'positive','scalar','integer','finite','nonnan','nonempty'},'','Data length');
        end
        
        function NumberOfBytes = getNumberOfBytes(DataType)
            matlabshared.svd.SPI.allowedDataType(DataType);
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
    
    % System object methods
    methods (Access = protected)
        function varargout = stepImpl(~,varargin)
            varargout{1} = 0;
        end
        
        function validateInputsImpl(obj,varargin)
            % Run this always in Simulation
            if coder.target('MATLAB') || coder.target('RtwForSim') || coder.target('RtwForRapid')
                if (1 == getNumInputsImpl(obj))
                    validateattributes(varargin{1},{'numeric'},...
                        {'vector'},'','Data');
                end
            end
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            switch prop
                case 'ActiveLowSSPin'
                    flag = isequal(obj.Mode, 'Slave');
                case 'Direction'
                    flag = true;
                case 'UseCustomSSPin'
                    flag = isequal(obj.Mode, 'Slave');
                case 'BusSpeed'
                    if isempty(obj.Hw) || isequal(obj.Mode, 'Slave')
                        flag = true;
                    else
                        flag = ~logical(getBusSpeedParameterVisibility(obj.Hw, obj.SPIModule));
                    end
                otherwise
                    flag = false;
            end
        end
    end
    
    methods (Access = protected, Static)
        function ClockModeValue = getSPIModeTypeValue(ModeValueStr)
            coder.inline('always');
            switch ModeValueStr
                case '0'
                    ClockModeValue = 'MW_SPI_MODE_0';
                case '1'
                    ClockModeValue = 'MW_SPI_MODE_1';
                case '2'
                    ClockModeValue = 'MW_SPI_MODE_2';
                case '3'
                    ClockModeValue = 'MW_SPI_MODE_3';
                otherwise
                    ClockModeValue = 'MW_SPI_MODE_0';
            end            
        end
        
        function FirstTransferBitValue = getSPIFirstTransferBit(FirstTransferBitStr)
            coder.inline('always');
            switch FirstTransferBitStr
                case {true,'Most significant bit (MSB)'}
                    FirstTransferBitValue = 'MW_SPI_MOST_SIGNIFICANT_BIT_FIRST';
                case {false','Least significant bit (LSB)'}
                    FirstTransferBitValue = 'MW_SPI_LEAST_SIGNIFICANT_BIT_FIRST';
                otherwise
                    FirstTransferBitValue = 'MW_SPI_MOST_SIGNIFICANT_BIT_FIRST';
            end            
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyListMain, PropertyListAdvanced] = getPropertyGroupsImpl
            %Mode Mode
            ModeProp = matlab.system.display.internal.Property('Mode', 'Description', 'svd:svd:SPIModePrompt');
            %SPIModule SPI module
            SPIModuleProp = matlab.system.display.internal.Property('SPIModule', 'Description', 'svd:svd:SPIModulePrompt');
            %BusSpeed Bus speed (in Hz)
            BusSpeedProp = matlab.system.display.internal.Property('BusSpeed', 'Description', 'svd:svd:SPIBusSpeedPrompt');
            %Pin Slave select pin
            PinProp = matlab.system.display.internal.Property('Pin', 'Description', 'svd:svd:SPISlaveSelectPrompt');
            %FirstBitToTransfer First bit to transfer
            FirstBitToTransferProp = matlab.system.display.internal.Property('FirstBitToTransfer', 'Description', 'svd:svd:SPIFirstBitPrompt');
            %ClockMode Mode (Clock polarity and phase)
            ClockModeProp = matlab.system.display.internal.Property('ClockMode', 'Description', 'svd:svd:SPIClockModePrompt');
            %UseCustomSSPin Slave select calling method
            UseCustomSSPinProp = matlab.system.display.internal.Property('UseCustomSSPin', 'Description', 'svd:svd:SPIUseCustomSSPinPrompt');
            %ActiveLowSSPin Slave select pin polarity
            ActiveLowSSPinProp = matlab.system.display.internal.Property('ActiveLowSSPin', 'Description', 'svd:svd:SPIActiveLowSSPinPrompt');
             
            PropertyListMainOut = {SPIModuleProp,ModeProp,BusSpeedProp,PinProp,FirstBitToTransferProp,ClockModeProp};
            PropertyListAdvancedOut = {UseCustomSSPinProp,ActiveLowSSPinProp};
            
            % Create mask display
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Main',...
                'PropertyList',PropertyListMainOut);
            AdvancedGroup = matlab.system.display.SectionGroup(...
                'Title','Advanced',...
                'PropertyList',PropertyListAdvancedOut);
            
            groups = [MainGroup, AdvancedGroup];

            % Output property list if requested
            if nargout > 1
                PropertyListMain = PropertyListMainOut;
                PropertyListAdvanced = PropertyListAdvancedOut;
            end
        end
    end
end
