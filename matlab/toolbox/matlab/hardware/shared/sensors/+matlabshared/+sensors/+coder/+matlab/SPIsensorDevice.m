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
        function spiObj = SPIsensorDevice(obj,cspin)
            % parameter Validation
            if isa(obj.Parent,'matlabshared.hwsdk.controller')
                spiObj.Device = device(obj.Parent,'SPIChipSelectPin',cspin);
            else
                spiObj.ProtocolObj = obj.Parent.ProtocolObj;
                spiObj.Device  = matlabshared.sensors.coder.matlab.SPIDevice(obj.Parent,cspin);
                spiObj.SPIChipSelectPin = spiObj.Device.ChipSelectPin;
                spiObj.SPIDriverObj = spiObj.Device.InterfaceObj;
            end
        end

        function closeDev(obj)
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

            Address = zeros(1,bytesToRead+1);
            Address(1) = registerAddress;

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
                Address(loop+1) = actualAddr;
            end

            % writeReadSPI/MultiByteWriteReadSPI function accepts the
            % register address as a series of uint8 bytes
            switch(precision)
                case 'uint32'
                    readAddr = typecast(uint32(Address),'uint8');
                case 'uint16'
                    readAddr = typecast(uint16(Address),'uint8');
                case 'uint8'
                    readAddr = typecast(uint8(Address),'uint8');
                otherwise
                    readAddr = typecast(uint8(Address),'uint8');
            end

            % Check for the multiByteReadValue, If set, append the value of
            % multiByteReadValue to the readAddr to determine the chip select toggle frequency
            % if ~isempty(multiByteReadValue)
            %     readAddr = [readAddr multiByteReadValue];
            % end

            count = size(readAddr,2);

            readValue = zeros(1,count,'double');

            j= 1;
            for loop = 1:count/2
                val = double(writeRead(obj.Device,uint8([readAddr(j) readAddr(j+1)])));
                readValue(j:j+1) = val;
                j = j+2;
            end
            datatypeConv = typecast(uint8(readValue),precision);
            readValue = datatypeConv;
            timestamp = 0;
            status = 0;
        end
    end

    methods(Static)
        function validateSPISensorArguments(cspin,i2caddress)
            if isequal(cspin,'0')
                error(message('matlab_sensors:general:InvalidSPIChipSelect'));
            elseif ~isequal(i2caddress,0)
                error(message('matlab_sensors:general:InvalidSensorObject','I2CAddress'));
            end
        end
    end
end
