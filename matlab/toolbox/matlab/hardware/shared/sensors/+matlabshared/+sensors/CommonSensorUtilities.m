classdef (Hidden, Abstract) CommonSensorUtilities < matlabshared.sensors.internal.Accessor

    % This class provides internal API to be used by sensor objects.
    % Hardware class should inherit from it. But if the target hardware is
    % HWSDK based target, no need to inherit from it because
    % matlabshared.hwsdk.controller also provides functions with same
    % signature.

    %#codegen
    % Copyright 2020-2023 The MathWorks, Inc.

    methods(Abstract, Access = protected)
        dev = getDeviceImpl(obj, varargin);
    end

    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will be replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.CommonSensorUtilities';
        end
    end

    methods (Access = {?matlabshared.sensors.internal.Accessor})
        function delayFunctionForHardware(~,~)
            % This delay is interms of seconds. Factor represents number of seconds
        end

        function timeInSec = getCurrentTimeImpl(~,~)
            timeInSec= 0;
        end
    end

    methods(Access = {?matlabshared.sensors.internal.Accessor})

        function dev = getDevice(obj, varargin)
            % This function returns the I2C or Serial device object to be
            % used by sensor objects.
            dev = getDeviceImpl(obj, varargin{:});
            try
                assert(isa(dev, 'matlabshared.sensors.I2CDeviceWrapper')||...
                    isa(dev, 'matlabshared.sensors.SerialDeviceWrapper') || ...
                    isa(dev, 'matlabshared.sensors.SPIDeviceWrapper')||...
                    isa(dev, 'matlabshared.i2c.device'))  % Specially for Raspi as it is both a CommonSensorUtility and a HWSDK user.
            catch
                error(message('matlab_sensors:general:invalidHwObjSensor'));
            end
        end
    end
end
