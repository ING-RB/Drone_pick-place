classdef (Hidden) I2CSensorUtilities < matlabshared.sensors.internal.Accessor
    
    % This class provides internal API to be used by I2C sensor
    % infrastructure. It should be inherited by the hardware class to
    % support I2C sensors. It has similar APIs as matlabshared.i2c.controller.
    % So HWSDK based targets do not need to inherit this.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    %#codegen
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will willbe replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.I2CSensorUtilities';
        end
    end
    
    methods(Abstract, Access = public)
        % Implement the following methods in the hardware class
        address = scanI2CBus(obj, bus);
        buses = getAvailableI2CBusIDs(obj);
        showI2CProperties(obj, interface, i2cAddress, bus, sclPin, sdaPin, bitRate, showAllProperties);
    end
    
    methods(Access = public,Hidden)
        function [dispValue,numericValue] = getValidatedI2CBusInfo(obj,bus)
            availableBuses = getAvailableI2CBusIDs(obj);
            if ismember(bus,availableBuses)
                dispValue = bus;
                numericValue = bus;
            else
                error(message('matlab_sensors:general:invalidBusValue', 'I2C', num2str(availableBuses)));
            end
        end
    end
end
