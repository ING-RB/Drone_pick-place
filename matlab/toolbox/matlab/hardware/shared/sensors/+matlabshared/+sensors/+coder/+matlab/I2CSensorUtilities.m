classdef (Hidden) I2CSensorUtilities < handle
    % This class provides internal API to be used by sensor infrastructure
    % for code generation.
    
    % Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    methods(Abstract, Access = public)
        % Implement the following methods in the hardware class
        buses = getAvailableI2CBusIDs(obj);
        i2cDriverObj = getI2CDriverObj(obj, busNum);
    end
    
     methods(Access = public,Hidden)
        function [dispValue,numericValue] = getValidatedI2CBusInfo(obj,bus)
            % Targets which requires non numeric values as bus need to
            % overload this function. This is default implementation
            % assuming bus is a numeric value and getAvailableI2CBusIDs(obj);
            % returns numeric array
            availableBuses = getAvailableI2CBusIDs(obj);
            coder.internal.assert(isnumeric(availableBuses), ...
                'matlab_sensors:general:invalidAvailableBusType', 'I2C', num2str(availableBuses));
            coder.internal.assert(isnumeric(bus) && isscalar(bus) &&...
                isreal(bus) &&  bus>=0 && floor(bus)==bus , ...
                'matlab_sensors:general:invalidBusType', 'I2C', num2str(availableBuses));
            coder.internal.assert(ismember(bus, availableBuses),...
                'matlab_sensors:general:invalidBusValue', 'I2C', num2str(availableBuses));
                dispValue = bus;
                numericValue = bus;
        end
    end
end