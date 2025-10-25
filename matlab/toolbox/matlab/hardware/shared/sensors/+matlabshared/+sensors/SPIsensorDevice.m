classdef SPIsensorDevice < matlabshared.sensors.sensorDevice & matlabshared.sensors.internal.Accessor

    %   Copyright 2023 The MathWorks, Inc.

    %#codegen

    properties
        Interface = "SPI"
        Device
        SPIDriverObj
        ProtocolObj
        SPIBus
        OnDemandFlag = 1;
        SampleRate;
        SamplePerRead;
    end

    properties
        isCSPinActiveLow
    end

    properties(Access=private)
        SPIChipSelectPin
    end

    methods
        function spiObj = SPIsensorDevice(obj,mode,varargin)
            cspin = varargin{1}.SPIChipSelectPin;
            % parameter Validation
            if isa(obj.Parent,'matlabshared.hwsdk.controller')
                spiObj.Device = device(obj.Parent,'SPIChipSelectPin',cspin,'SPIMode',mode);
                switch (string(spiObj.Device.ActiveLevel))
                    case "low"
                        spiObj.isCSPinActiveLow = 1;
                    case "high"
                        spiObj.isCSPinActiveLow = 0;
                end
                spiObj.SPIDriverObj = matlabshared.ioclient.peripherals.SPI;
                spiObj.ProtocolObj = obj.Parent.getProtocolObject();
                spiObj.SPIBus = obj.Parent.AvailableSPIBusIDs - 1;
                spiObj.SamplePerRead = varargin{1}.SamplesPerRead;
                spiObj.SampleRate = varargin{1}.SampleRate;
                spiObj.SPIChipSelectPin = str2double(spiObj.Device.SPIChipSelectPin(2:end));
            else
                spiObj.ProtocolObj = obj.Parent.ProtocolObj;
                spiObj.Device  = obj.Parent.getDevice(cspin);
                spiObj.SPIChipSelectPin = spiObj.Device.ChipSelectPin;
                spiObj.SPIDriverObj = spiObj.Device;
            end
        end

        function showProperties(obj, showAll)
            % This method is used for displaying SPI device object. The
            % hardware object inherits this method to modify the object
            % display.

            fprintf('             Interface: "%s"\n', obj.Device.Interface);
            fprintf('      SPIChipSelectPin: "%s"\n', obj.Device.SPIChipSelectPin);
            fprintf('                SCLPin: "%s"\n', obj.Device.SCLPin);
            fprintf('                SDIPin: "%s"\n', obj.Device.SDIPin);
            fprintf('                SDOPin: "%s"\n', obj.Device.SDOPin);

            if showAll
                fprintf('               SPIMode: %d\n', obj.Device.SPIMode);
                fprintf('           ActiveLevel: "%s"\n', obj.Device.ActiveLevel);
                fprintf('              BitOrder: "%s"\n', obj.Device.BitOrder);
                fprintf('               BitRate: %d (bits/s)\n', obj.Device.BitRate);
            end

            fprintf('\n');
        end
    end

    methods(Access=protected)
        function writeRegisterImpl(obj, registerAddress, data)
            writeRead(obj.Device,[registerAddress data]);
        end

        function writeImpl(obj,registerAddress)
        end

        function readValue = readRegisterImpl(obj, registerAddress,varargin)
            readValue = writeRead(obj.Device,uint8(registerAddress));
        end

        function [readValue,status,timestamp] = readRegisterDataImpl(obj, registerAddress,bytesToRead,precision,multiByteReadValue)

            actualAddr = registerAddress;

            % Get the size of the data type and increment the register
            % address for a multi byte read
            switch(precision)
                case 'uint32'
                    numBytes = 0x4;
                case 'uint16'
                    numBytes = 0x2;
                otherwise
                    numBytes = 0x1;
            end

            % Group the addresses to be read
            for loop = 1:bytesToRead
                if isequal(loop,bytesToRead)
                    % SPI functions as a shift register, requires a dummy read to retrieve the register value
                    % The value of actualAddr is set to 0 for the purpose of a dummy read.
                    actualAddr = 0x00;
                else
                    actualAddr = actualAddr + numBytes;
                end
                registerAddress = [registerAddress actualAddr];
            end

            % writeReadSPI/MultiByteWriteReadSPI function accepts the
            % register address as a series of uint8 bytes
            switch(precision)
                case 'uint32'
                    readAddr = typecast(uint32(registerAddress),'uint8');
                case 'uint16'
                    readAddr = typecast(uint16(registerAddress),'uint8');
                case 'uint8'
                    readAddr = typecast(uint8(registerAddress),'uint8');
                otherwise
                    readAddr = typecast(uint8(registerAddress),'uint8');
            end

            % Check for the multiByteReadValue, If set, append the value of
            % multiByteReadValue to the readAddr to determine the chip select toggle frequency
            if ~isempty(multiByteReadValue)
                readAddr = [readAddr multiByteReadValue];
            end

            count = size(readAddr,2);

            if(obj.OnDemandFlag)
                if ~isempty(multiByteReadValue)
                    % An extra byte is added to the readAddr to indicate the multibyte SPI read%
                    [val,~,~] = multiByteWriteReadSPI(obj.SPIDriverObj, obj.ProtocolObj, obj.SPIBus, obj.SPIChipSelectPin, obj.isCSPinActiveLow, count, readAddr);

                    % WriteReadSPI receives the bytes that correspond to the number of bytes sent as the address.
                    % The last byte of the 'val' corresponds to the byte sent for the multiByteReadValue. Therefore, the last byte is removed.
                    val = val(1:end-1);
                else
                    [val,~,~] = writeReadSPI(obj.SPIDriverObj, obj.ProtocolObj, obj.SPIBus, obj.SPIChipSelectPin, obj.isCSPinActiveLow, count, readAddr);
                end

                datatypeConv = typecast(uint8(val),precision);
                readValue = datatypeConv';
                timestamp = [];
                status = [];
            else
                if ~isempty(multiByteReadValue)
                    [val,status,timestamp] = multiByteWriteReadSPI(obj.SPIDriverObj, obj.ProtocolObj, obj.SPIBus, obj.SPIChipSelectPin, obj.isCSPinActiveLow, count, readAddr);
                    val(count:count:end) = [];
                    datatypeConv = typecast(uint8(val),precision);
                    dimen = reshape(datatypeConv,(count-1)/numBytes,obj.SamplePerRead);
                else
                    % Function writeReadSPI accept the address only in uint8 format. Typecast the address to uint8 %
                    [val,status,timestamp] = writeReadSPI(obj.SPIDriverObj, obj.ProtocolObj, obj.SPIBus, obj.SPIChipSelectPin, obj.isCSPinActiveLow, count, readAddr);
                    datatypeConv = typecast(uint8(val),precision);
                    dimen = reshape(datatypeConv,count,obj.SamplePerRead);
                end

                readValue = dimen';
            end
        end
    end

    methods(Static)
        function validateSPISensorArguments(obj)
            if isempty(obj.SPIChipSelectPin)
                error(message('matlab_sensors:general:InvalidSPIChipSelect'));
            elseif ~isempty(obj.I2CAddress)
                error(message('matlab_sensors:general:InvalidSensorObject','I2CAddress'));
            end
        end
    end
end
