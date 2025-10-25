classdef I2CsensorDevice < matlabshared.sensors.sensorDevice & matlabshared.sensors.internal.Accessor
    %   Copyright 2024 The MathWorks, Inc.
    %#codegen
    properties
        Device
        BusI2CDriver
        OnDemandFlag = 1;
        ProtocolObj;
    end
    properties
        Bus;
        I2CAddress;
        Interface = 'I2C';
        BitRate = 100000;
        SDAPin = '';
        SCLPin = '';
        SamplePerRead;
    end
    methods
        function i2cObj = I2CsensorDevice(obj,isSimulink,I2CAddressList,bus,i2caddress,varargin)
            % For all hwsdk based targets and for call from Simulink, bus value is expected to be numeric
            if ~isSimulink
                % the below functions are not required for Simulink. It
                % should be taken care from mask level
                % Validate the 'Bus' parameter if provided by the user
                availableBuses = getAvailableI2CBusIDs(obj.Parent);
                if(isnumeric(bus) && bus == uint32(0)) % check if value of the 'bus' is default value
                    if iscell(availableBuses)
                        i2cBus = availableBuses{1};
                    else
                        i2cBus = availableBuses(1);
                    end
                else
                    i2cBus = bus;
                end
            else
                % Bus value validation and default setting will be taken
                % care mask level for Simulink
                i2cBus = bus;
            end
            % For Simulink all validation related to Bus is done at mask level
            if ~isSimulink
                % For all hwsdk based targets bus value is expected to be numeric
                if isa(obj.Parent, 'matlabshared.sensors.I2CSensorUtilities') || isa(obj.Parent, 'matlabshared.sensors.coder.matlab.I2CSensorUtilities')
                    % Bus is the value which device Object takes as input and
                    % also will be visible to end user. BusI2CDriver is
                    % required for streaming, which uses IO client API
                    % which currently takes numeric value for buses
                    [i2cObj.Bus,i2cObj.BusI2CDriver] = obj.Parent.getValidatedI2CBusInfo(i2cBus);
                else
                    i2cObj.Bus =  i2cObj.validateI2CBus(i2cBus,availableBuses);
                    i2cObj.BusI2CDriver = i2cObj.Bus;
                end
            else
                i2cObj.Bus = bus;
                i2cObj.BusI2CDriver = i2cObj.Bus;
            end
            % Validate the 'I2CAddress' array provided by the user. In case
            % the parameter is absent, select the first element of
            % I2CAddressList property of each sensor unit object as default
            % I2CAddress.
            if isequal(i2caddress,uint32(0))
                I2CAddressIn = coder.const(I2CAddressList(1));
            else
                I2CAddressIn = coder.const(i2caddress);
            end
            coder.internal.assert(isnumeric(I2CAddressIn)||iscell(I2CAddressIn)||ischar(I2CAddressIn)||isstring(I2CAddressIn), 'matlab_sensors:general:invalidI2CAddressType');
            % convert the I2C Address into numeric array
            coder.extrinsic('matlabshared.sensors.internal.validateHexParameterRanged');
            % extrinsic function always returns mxArray unless type is
            % specified before
            I2CAddressNumeric = coder.const(matlabshared.sensors.internal.validateHexParameterRanged(I2CAddressIn));
            % Check if the given I2C Address is a possible I2C Address of
            % the particular sensor
            coder.internal.assert(any(ismember(I2CAddressList, I2CAddressNumeric)),...
                'matlab_sensors:general:incorrectI2CAddressSensor', num2str(I2CAddressList));
            i2cAddressInternal = coder.const(uint8(I2CAddressNumeric(ismember(I2CAddressNumeric,I2CAddressList))));
            % Give data type double for user visible I2C Address
            i2cObj.I2CAddress = coder.const(double(i2cAddressInternal));
            coder.extrinsic('matlabshared.sensors.internal.validateHexParameterRanged');
            if ismethod(obj.Parent,'getDevice')
                % When we use the system object based approach using m-drivers
                i2cObj.Device = obj.Parent.getDevice(obj.Parent, i2cAddressInternal,bus);
            else
                % Incase of using existing I2CDevice C-Driver
                i2cObj.Device = matlabshared.sensors.coder.matlab.device(obj.Parent, i2cAddressInternal, i2cObj.BusI2CDriver);
            end
        end
        function closeDev(obj)
            closeI2CDev(obj.Device);
        end
    end
    methods(Access=protected)
        function writeImpl(obj,registerAddress)
            write(obj.Device,registerAddress);
        end
        function writeRegisterImpl(obj, registerAddress, data)
            writeRegister(obj.Device,registerAddress, data);
        end
        function readValue = readRegisterImpl(obj, registerAddress,count,precision)
            readValue = readRegister(obj.Device,uint8(registerAddress),count,precision);
        end
        function [readValue,status,timestamp] = readRegisterDataImpl(obj, DataRegister, numBytes, precision,~)
            % during streaming configuration, call 'readRegister' which
            % performs a number of validation checks.
            readValue = readRegister(obj.Device, DataRegister, numBytes, precision);
            status = 0;
            timestamp = 0;
        end
    end
    methods(Access = private)
        function value = validateI2CBus(~, bus, availableBuses)
            % Change the error IDs
            coder.internal.assert(isnumeric(bus) && isscalar(bus) &&...
                isreal(bus) &&  bus>=0 && floor(bus)==bus , ...
                'matlab_sensors:general:invalidBusType', 'I2C', num2str(availableBuses));
            coder.internal.assert(ismember(bus, availableBuses),...
                'matlab_sensors:general:invalidBusValue', 'I2C', num2str(availableBuses));
            value = bus;
        end
    end
    methods(Static)
        function validateI2CSensorArguments(cspin)
            if ~isequal(cspin,'0')
                error(message('matlab_sensors:general:InvalidSensorObject','SPIChipSelectPin'));
            end
        end
    end
end
