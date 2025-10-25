classdef SPIDevice < matlabshared.sensors.SPIDeviceWrapper
    %SPIDevice class is used create a lightweight device object to use in
    %Simulink IO

    %  Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the sub class. Sensor objects
        % access these properties directly.
        ChipSelectPin
        Bus
        bitRate
        SPIDriverObj
    end

    % properties(Access = ?matlabshared.sensors.internal.Accessor)
    %     % It holds the IO Client object that is used by SPI Device classs.
    %     SPIDriverObj
    % end

    properties(Access = protected)
        Parent
    end

    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.sensors.coder.matlab.SPIDevice';
        end
    end

    methods
        function obj = SPIDevice(parent,varargin)

            obj.Parent = parent;
            obj.ChipSelectPin =  str2double(varargin{1});
            obj.SPIDriverObj = getSPIDriverObj(obj.Parent);

            [clkfrequency, mode, bitorder] = codertarget.arduinobase.internal.getArduinoSPIProperties();

            % openSPI: [ProtocolHandle, bus, MOSIPin, MISOPin, SCLK, CSPin, varargin]
            % sets SPI mode, frequency, bitorder, register
            % size, and whether CS pin is Active low/high
            openSPI(obj.SPIDriverObj, obj.Parent.ProtocolObj,0,0,0,0,obj.ChipSelectPin, clkfrequency,"low", 0, 8, mode, bitorder);
        end

        function delete(obj)
            % Check if the objects are not deleted or is made empty in any earlier stages
            if isvalid(obj.SPIDriverObj) && isvalid(obj.Parent)
                if ~isempty(obj.SPIDriverObj) && ~isempty(obj.Parent.ProtocolObj)
                    closeSPI(obj.SPIDriverObj,obj.Parent.ProtocolObj,0,0,0,0,obj.ChipSelectPin);
                end
            end
        end
    end

    methods
        function value = writeRead(obj,addr)
            count = size(addr,2);
            value = writeReadSPI(obj.SPIDriverObj, obj.Parent.ProtocolObj, 0, obj.ChipSelectPin, 1, count, addr);
        end

        function [val,status,timestamp] = multiByteWriteReadSPI(obj, ~, ~, ~, ~, count, readAddr)
            [val,~,~] = multiByteWriteReadSPI(obj.SPIDriverObj, obj.Parent.ProtocolObj, 0, obj.ChipSelectPin,1, count, readAddr);
            status = 0;
            timestamp = 0;
        end
    end
end
