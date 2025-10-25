classdef TargetI2CSensorUtilities < matlabshared.sensors.simulink.internal.SensorSimulinkBase &...
        matlabshared.sensors.CommonSensorUtilities &...
        matlabshared.sensors.I2CSensorUtilities
    
    
    %TargetI2CSensorUtilities class which inherits and implements all the
    % APIs required for sensor workflow.
    
    %   Copyright 2020-2023 The MathWorks, Inc.
    %#codegen
    properties
        BitRate = 1e5;
    end
    
    methods
        function addresses = scanI2CBus(obj, bus)
            addresses = obj.ProtocolObj.scanI2CBus(bus);
            if addresses == 0
                error(message('matlab_sensors:general:I2CAddressNotFound'));
            end
        end
        
        function i2cIoClientObj = getI2CDriverObj(obj,~)
            % For targets which doesn't have IO, redirection from IO client
            % APIs will require a dependency on IO server. To avoid the 
            % dependencty, use the coder components of IO client API
            % directly.
            if coder.target('MATLAB') && obj.IsIOEnable
                i2cIoClientObj = matlabshared.ioclient.peripherals.I2C;
            else
                i2cIoClientObj = matlabshared.devicedrivers.coder.I2C;
            end
        end
        
        function buses = getAvailableI2CBusIDs(~)
        end

        function showI2CProperties(~, ~, ~, ~, ~, ~, ~, ~)
        % (obj, interface, i2cAddress, bus, sclPin, sdaPin, bitRate,
            % showAllProperties)
        % Simulink functionalities are independent of display.
        end
    end
    
    methods(Access = protected)
        function dev = getDeviceImpl(~, varargin)
            dev = matlabshared.sensors.simulink.internal.I2CDevice(varargin{:});
        end
    end
end
