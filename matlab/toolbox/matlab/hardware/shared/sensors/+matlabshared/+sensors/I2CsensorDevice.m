classdef I2CsensorDevice < matlabshared.sensors.sensorDevice & matlabshared.sensors.internal.Accessor

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties
        Device
        BusI2CDriver
        OnDemandFlag = 1;
        Parent;
    end
    properties (Access = private)
        I2CAddressesFound
    end

    properties
        Bus;
        I2CAddress;
        Interface = 'I2C';
        BitRate = 100000;
        SDAPin = '';
        SCLPin = '';
    end

    methods
        function i2cObj = I2CsensorDevice(obj,isSimulink,parserObj,hardwareObj,I2CAddresslist)
            % For all hwsdk based targets and for call from Simulink, bus value is expected to be numeric
            if ~isSimulink && any(contains(parserObj.UsingDefaults,'Bus'))
                availableBusIds = obj.Parent.getAvailableI2CBusIDs();
                if iscell(availableBusIds)
                    i2cObj.Bus = availableBusIds{1};
                else
                    i2cObj.Bus = availableBusIds(1);
                end
            else
                i2cObj.Bus = parserObj.Results.Bus;
            end

            if isa(obj.Parent, 'matlabshared.sensors.I2CSensorUtilities') && ~isSimulink
                % Bus is the value which device Object takes as input and
                % also will be visible to end user. BusI2CDriver is
                % required for streaming, which uses IO client API
                % which currently takes numeric value for buses
                [i2cObj.Bus,i2cObj.BusI2CDriver] = obj.Parent.getValidatedI2CBusInfo(i2cObj.Bus);
            end

            i2cObj.BusI2CDriver = i2cObj.Bus;
            isSensorBoard = matlabshared.sensors.sensorBase.isSensorBoard('get');

            if ~isSensorBoard
                validateI2CAddress(i2cObj,parserObj);
            end
            if ~isa(obj.Parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilitiesDeviceBased')
                % Get the addresses of any I2C device connected.
                I2CAddressesFound = scanI2CBus(obj.Parent,i2cObj.Bus);
                if iscellstr(I2CAddressesFound) || isstring(I2CAddressesFound)
                    I2CAddressesFound = hex2dec(I2CAddressesFound);
                end
                if(~any(contains(parserObj.UsingDefaults,'I2CAddress')))
                    % take the user given I2C Address
                    givenI2CAddress = parserObj.Results.I2CAddress;
                    % This function here simply used to convert the I2C
                    % address to appropriate form.
                    givenI2CAddressAfterConversion = matlabshared.sensors.internal.validateHexParameterRanged(givenI2CAddress);
                    % check if this address is valid for the sensor. Check the
                    % given address is in the expected list of I2C address of
                    % the sensor.
                    i2cAddress = I2CAddresslist(ismember(I2CAddresslist,givenI2CAddressAfterConversion));
                    % i2cAddress will be empty when user given address doesn't match with
                    % the device address
                    if(isempty(i2cAddress))
                        errorStr = ['0x',dec2hex(I2CAddresslist(1)),'(' num2str(I2CAddresslist(1)),')'];
                        for i=2:numel(I2CAddresslist)
                            errorStr = [errorStr, ' or ','0x',dec2hex(I2CAddresslist(i)),'(' num2str(I2CAddresslist(i)),')'];
                        end
                        error(message('matlab_sensors:general:incorrectI2CAddressSensor',string(errorStr)));
                    end
                    % Check if the user given address which is also present in
                    % the sensor I2C address list is found on the I2C bus
                    if ~any(ismember(i2cAddress,I2CAddressesFound))
                        % happens when user has connected a different I2C device
                        error(message('matlab_sensors:general:expectedI2CDeviceNotFound'));
                        % If multiple I2C devices are found on the same bus
                    elseif nnz(ismember(I2CAddressesFound,i2cAddress))>1
                        error(message('matlab_sensors:general:multipleSameI2CAddress'));
                    end
                    i2cObj.I2CAddress = i2cAddress;
                else
                    % user has not given an I2C address. Check if the I2C
                    % addresses return by scanI2CBus is matching expected I2C
                    % address of the sensor
                    i2cObj.I2CAddress = double(I2CAddresslist(ismember(I2CAddresslist,I2CAddressesFound)));
                    if(isempty(i2cObj.I2CAddress))
                        % happens when user has connected a different I2C device
                        error(message('matlab_sensors:general:expectedI2CDeviceNotFound'));
                    elseif(numel(i2cObj.I2CAddress) > 1)
                        % multiple I2C devices of same type detected
                        error(message('matlab_sensors:general:multipleSameI2CAddress'));
                    end
                end
                i2cObj.Device = obj.Parent.getDevice(hardwareObj,'I2CAddress',i2cObj.I2CAddress,'Bus',i2cObj.Bus);
                i2cObj.Parent = obj.Parent;
            else
                % When we use the system object based approach using m-drivers
                if(~any(contains(parserObj.UsingDefaults,'I2CAddress')))
                    givenI2CAddress = parserObj.Results.I2CAddress;
                    % This function here simply used to convert the I2C
                    % address to appropriate form.
                    givenI2CAddressAfterConversion = matlabshared.sensors.internal.validateHexParameterRanged(givenI2CAddress);
                    i2cObj.I2CAddress = givenI2CAddressAfterConversion;
                    i2cObj.I2CAddress = I2CAddresslist(ismember(I2CAddresslist,givenI2CAddressAfterConversion));
                    i2cObj.Device = obj.Parent.getDevice(hardwareObj,'I2CAddress',i2cObj.I2CAddress,'Bus',i2cObj.Bus);
                    i2cObj.Parent = obj.Parent;
                    if ~ismember(i2cObj.I2CAddress,I2CAddresslist)
                        % happens when user has connected a different I2C device
                        error(message('matlab_sensors:general:expectedI2CDeviceNotFound'));
                    end
                    I2CAddressesFound = scanI2CBusSensor(i2cObj.Device, I2CAddresslist);
                    if ~ismember(i2cObj.I2CAddress,I2CAddressesFound)
                        % if the specified address is not in I2CAddressesFound list
                        errorStr = ['0x',dec2hex(I2CAddresslist(1)),'(' num2str(I2CAddresslist(1)),')'];
                        for i=2:numel(I2CAddresslist)
                            errorStr = [errorStr, ' or ','0x',dec2hex(I2CAddresslist(i)),'(' num2str(I2CAddresslist(i)),')'];
                        end
                        error(message('matlab_sensors:general:incorrectI2CAddressSensor',string(errorStr)));
                    end
                else
                    i2cObj.I2CAddress=I2CAddresslist;
                    i2cObj.Device = obj.Parent.getDevice(hardwareObj,'I2CAddress',i2cObj.I2CAddress,'Bus',i2cObj.Bus);
                    i2cObj.Parent = obj.Parent;
                end
            end
            if ~isSimulink
                i2cObj.BitRate =  i2cObj.Device.BitRate;
                if isprop(i2cObj.Device,'SCLPin') && isprop(i2cObj.Device,'SDAPin') 
                    i2cObj.SDAPin = i2cObj.Device.SDAPin;
                    i2cObj.SCLPin = i2cObj.Device.SCLPin;
                end
            end
        end

        function showProperties(obj, showAll)

            fprintf('             Interface: "%s"\n', obj.Device.Interface);
            fprintf('            I2CAddress: %-1d ("0x%02s")\n', obj.Device.I2CAddress(1), dec2hex(obj.Device.I2CAddress(1)));
            for i = 2:numel(obj.Device.I2CAddress)
                fprintf('                      : %-1d ("0x%02s")\n',obj.Device.I2CAddress(i), dec2hex(obj.Device.I2CAddress(i)));
            end
            fprintf('                   Bus: %d\n', obj.Device.Bus);

            fprintf('                SCLPin: "%s"\n', obj.Device.SCLPin);
            fprintf('                SDAPin: "%s"\n', obj.Device.SDAPin);

            if showAll
                fprintf('               BitRate: %d (bits/s)\n', obj.Device.BitRate);
            end

            fprintf('\n');
        end
    end

    methods(Access=protected)
        function validateI2CAddress(~,parserObj)
            if ~any(contains(parserObj.UsingDefaults,'I2CAddress'))
                givenI2CAddress = parserObj.Results.I2CAddress;
                validateattributes(givenI2CAddress,{'numeric','string','char'},{'nonempty'},'','I2CAddress');
                if ischar(givenI2CAddress)
                    givenI2CAddress = string(givenI2CAddress);
                end
                validateattributes(givenI2CAddress,{'numeric','string'},{'nonempty'},'','I2CAddress');
            end
        end

        function writeImpl(obj, registerAddress)
            write(obj.Device,registerAddress);
        end

        function writeRegisterImpl(obj, registerAddress, data)
            writeRegister(obj.Device,registerAddress, data);
        end

        function readValue = readRegisterImpl(obj, registerAddress,count,precision)
            readValue = readRegister(obj.Device,uint8(registerAddress),count,precision);
        end

        function [readValue,status,timestamp] = readRegisterDataImpl(obj, DataRegister, numBytes, precision, ~)
            if(obj.OnDemandFlag)
                % during streaming configuration, call 'readRegister' which
                % performs a number of validation checks.
                readValue = readRegister(obj.Device, DataRegister, numBytes, precision);
                status = [];
                timestamp = [];
            else
                % these validation checks can be skipped during streaming
                % for speed enhancement reasons.
                % Arduino Bus IDs are 0 and 1.
                [readValue,status,timestamp] = registerI2CRead(obj.Device.I2CDriverObj, obj.Parent.getProtocolObject(), obj.BusI2CDriver, obj.Device.I2CAddress, DataRegister, numBytes);
            end
        end
    end

    methods(Static)
        function validateI2CSensorArguments(obj)
            if ~isempty(obj.SPIChipSelectPin)
                error(message('matlab_sensors:general:InvalidSensorObject','SPIChipSelectPin'));
            end
        end
    end
end
