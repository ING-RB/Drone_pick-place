classdef (Hidden) device < handle
    
    %  Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    properties(Access = private)
        Bus uint8
        DeviceAddress
    end
    
    properties(Access = private)
        InterfaceObj  % I2C or SPI driver object
    end
    
    methods
        function obj = device(parent, deviceAddress, bus)
            obj.Bus = bus;
            obj.DeviceAddress = deviceAddress;
            obj.InterfaceObj = getI2CDriverObj(parent, obj.Bus);
            start(obj);
        end
        
        function write(obj, dataIn)
            rawI2CWrite(obj.InterfaceObj,  obj.DeviceAddress, dataIn);
        end

        function writeRegister(obj, registerAddress, data)
            registerI2CWrite(obj.InterfaceObj, obj.DeviceAddress, registerAddress, data);
        end
        
        function [data, varargout] = readRegister(obj, registerAddress, numBytes, ~)
            if nargin<3
                numBytes = 1;
            end
            if nargout > 1
                [data, status] = registerI2CRead(obj.InterfaceObj, obj.DeviceAddress, registerAddress, numBytes);
                varargout{1} = status;
            else
                data = registerI2CRead(obj.InterfaceObj, obj.DeviceAddress, registerAddress, numBytes);
            end
        end
        
        function closeI2CDev(obj)
            % Explicit calls to delete() is not supported for codegen. 
            % Hence adding closeI2CDev function to close device object.
            if ~isempty(obj.InterfaceObj)
               closeI2CBus(obj.InterfaceObj)
            end
        end
    end
    
    methods(Access = private)
        function start(obj)
            openI2CBus(obj.InterfaceObj, obj.Bus);
        end
    end
end