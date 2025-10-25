classdef TargetSPISensorUtilities < matlabshared.sensors.simulink.internal.SensorSimulinkBase &...
        matlabshared.sensors.CommonSensorUtilities &...
        matlabshared.sensors.SPISensorUtilities

    %TargetSPISensorUtilities class which inherits and implements all the
    % APIs required for sensor workflow.

    %   Copyright 2023 The MathWorks, Inc.
    %#codegen
    properties
        BitRate = 1e5;
    end

    methods
        function spiIoClientObj = getSPIDriverObj(obj,~)
            % For targets which doesn't have IO, redirection from IO client
            % APIs will require a dependency on IO server. To avoid the
            % dependencty, use the coder components of IO client API
            % directly.
            spiIoClientObj = matlabshared.ioclient.peripherals.SPI;
        end

        function buses = getAvailableSPIBusIDs(~)
        end

        function cspins = getAvailableSPIChipSelectPins(~)
            cspins = 'D10';
        end

        function spipins = getAvailableSPIPins(obj)
            spipins = matlabshared.spi.controller.getAvailableSPIPins(obj);
        end

        function showSPIProperties(~, ~, ~, ~, ~, ~, ~, ~)
        end
    end

    methods(Access = protected)
        function dev = getDeviceImpl(obj, varargin)
            dev = matlabshared.sensors.simulink.internal.SPIDevice(obj,varargin{:});
        end
    end
end
