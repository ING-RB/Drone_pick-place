classdef (Hidden) SPIDevice < handle

    %  Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(GetAccess = public, SetAccess = protected)
        Bus uint8
        ChipSelectPin
    end

    properties(GetAccess = public, SetAccess = protected)
        InterfaceObj  % SPI driver object
    end

    properties(Access = protected)
        Parent
    end

    methods
        function obj = SPIDevice(parent,varargin)
            obj.Bus = 0;
            obj.ChipSelectPin = uint8(real(str2double(varargin{1})));
            obj.InterfaceObj = getSPIDriverObj(parent, obj.Bus);
            openSPI(obj.InterfaceObj, 0, 0, 0, 0, obj.ChipSelectPin, 0);
        end

        function data = writeRead(obj, registerAddress)
            data = writeReadSPI(obj.InterfaceObj,obj.ChipSelectPin,registerAddress);
        end

         function [val,status,timestamp] = multiByteWriteReadSPI(obj, ProtocolObj, SPIBus, chipselect, isCSPinActiveLow, count, readAddr)
            [val,~,~] = multiByteWriteReadSPI(obj.InterfaceObj, ProtocolObj, 0, obj.ChipSelectPin,1, count, readAddr);
        end

        function stopSPI(obj)
            if ~isempty(obj.InterfaceObj)
               closeSPI(obj.InterfaceObj,0,0,0, obj.ChipSelectPin);
            end
        end
    end
end
