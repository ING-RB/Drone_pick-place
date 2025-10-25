classdef Hardware < handle
    %Hardware Hardware base class
    %
    
    % Copyright 2015-2016 The MathWorks, Inc.
    %#codegen
    
    methods
        function obj = Hardware(varargin)
            coder.allowpcode('plain');
        end
    end
    
    methods (Abstract)
        % Digital I/O interface
        ret = getDigitalPinName(obj,pinNumber);
        ret = isValidDigitalPin(obj,pin);
        ret = getDigitalPinNumber(obj,pinName);
        
        % Analog input interface
        ret = getAnalogPinName(obj,pinNumber);
        ret = isValidAnalogPin(obj,pin);
        ret = getAnalogPinNumber(obj,pinName);
        
        % PWM interface
        ret = getPWMPinName(obj,pinNumber);
        ret = isValidPWMPin(obj, pin);
        ret = getPWMPinNumber(obj,pinName);
        ret = getMinimumPWMFrequency(obj);
        ret = getMaximumPWMFrequency(obj);
        
        % I2C interface
        ret = getI2CModuleName(obj,i2cModuleNumber);
%         ret = getI2CPins(obj);
        ret = isValidI2CModule(obj, i2cModule);
        ret = getI2CModuleNumber(obj,i2cModuleName);
        ret = getI2CBusSpeedInHz(obj, i2cModule);
        ret = getI2CMaximumBusSpeedInHz(obj, i2cModule);
        ret = getI2CMaxAllowedAddressBits(obj, i2cModule);
        
        % SPI interface
          % Target author functions
            % Get SPI module name based on the identifier
        ret = getSPIModuleName(obj,SPIModuleNumber);
            % validates correctness of SPI module
        ret = isValidSPIModule(obj, SPIModule);
            % Get SPI module identifier based on the name
        ret = getSPIModuleNumber(obj,SPIModuleName);
            % Get slave select Pin name from Pin number
        ret = getSlaveSelectPinName(obj,PinNumber);
            % Validate correct slave select Pin
        ret = isValidSlaveSelectPin(obj,SPIModule,Pin);
            % Get slave select Pin number from Pin name
        ret = getSlaveSelectPinNumber(obj,PinName);
            % Maximum allowed Bus speed
        ret = getSPIMaximumBusSpeedInHz(obj, SPIModule);
          % Target user functions
            % Get the SPI bus speed in Hz
        ret = getSPIBusSpeedInHz(obj, SPIModule);
            % Get SPI MOSI Pin
        ret = getSPIMosiPin(obj,SPIModule);
            % Get SPI MISO Pin
        ret = getSPIMisoPin(obj,SPIModule);
            % Get SPI SCK Pin
        ret = getSPIClockPin(obj,SPIModule);
            % Bus speed parameter visibility
                % true show the parameter on block
                % false hide the parameter
        ret = getBusSpeedParameterVisibility(obj,SPIModule);


        % SCI interface
            % Get SCI module name based on the identifier
        ret = getSCIModuleName(obj,SCIModuleNumber);
            % Validate is the SCI module available for the hardware
        ret = isValidSCIModule(obj, SCIModule);
            % Get the SCI module identifier from the name
        ret = getSCIModuleNumber(obj,SCIModuleName);
            % SCI module to consider as string
            % Linux based targets like Raspi are having virtual SCI.
        ret = getSCIModuleNameIsString(obj);
            % Get the SCI recevie pin name
        ret = getSCIReceivePin(obj,SCIModule);
            % Get the SCI transmit Pin name
        ret = getSCITransmitPin(obj,SCIModule);
            % Get SCI bus speed
        ret = getSCIBaudrate(obj, SCIModule);
            % Get the maximum allowed bus speed
        ret = getSCIMaximumBaudrate(obj, SCIModule);
            % Get Data bits
        ret = getSCIDataBits(obj, SCIModule);
            % Get the parity
        ret = getSCIParity(obj, SCIModule);
            % Get the stop bits
        ret = getSCIStopBits(obj, SCIModule);
            % Frame parameters visibility
            % true - visible
            % false - invisible
        ret = getSCIParametersVisibility(obj, SCIModule);
            % RTS pin for hardware flow control
        ret = getSCIRtsPin(obj, SCIModule);
            % CTS pin for hardware flow control
        ret = getSCICtsPin(obj, SCIModule);
            % Define Hardware flow control type
            % true - Enable RTS/CTS
            % false - No flow control
        ret = getSCIHardwareFlowControl(obj,SCIModule);
            % Define byte order for communicating with other SCI device
            % true - BigEndian
            % false - LittleEndian
        ret = getSCIByteOrder(obj,SCIModule);
    end
end
