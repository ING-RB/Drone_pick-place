classdef TargetI2CSensorUtilitiesDeviceBased < matlabshared.sensors.simulink.internal.SensorSimulinkBase &...
        matlabshared.sensors.CommonSensorUtilities

    %TargetI2CSensorUtilities class which inherits and implements all the
    % APIs required for sensor workflow.

    %   Copyright 2020-2023 The MathWorks, Inc.
      %#codegen
    properties
        BitRate = 1e5;
    end
    methods
        function showI2CProperties(~, ~, ~, ~, ~, ~, ~, ~)
            % (obj, interface, i2cAddress, bus, sclPin, sdaPin, bitRate,
            % showAllProperties)
            % Simulink functionalities are independent of display.
        end
    end

end
