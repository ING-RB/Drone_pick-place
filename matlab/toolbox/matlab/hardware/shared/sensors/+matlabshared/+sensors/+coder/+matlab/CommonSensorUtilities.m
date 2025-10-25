classdef (Hidden, Abstract) CommonSensorUtilities < handle

    % This class is the codegen class for
    % matlabshared.sensors.CommonSensorUtilities. It does not add any
    % feature. Rather this empty class ensures that when a hardware class
    % inherits matlabshared.sensors.CommonSensorUtilities, no unneccessary
    % error is thrown while generating code from sensor object.

    % Copyright 2024 The MathWorks, Inc.

    %#codegen

    methods(Abstract, Access = protected)
        dev = getDeviceImpl(obj, varargin);
    end
    methods (Access = {?matlabshared.sensors.internal.Accessor})
        function delayFunctionForHardware(obj,factor)
            % This delay is interms of seconds. Factor represents number of seconds
        end
    end
    methods
        function dev = getDevice(obj, i2cAddress, bus, varargin)
            % This function returns the I2C or Serial device object to be
            % used by sensor objects.
            dev = getDeviceImpl(obj, i2cAddress, bus, varargin{:});
        end
    end
end