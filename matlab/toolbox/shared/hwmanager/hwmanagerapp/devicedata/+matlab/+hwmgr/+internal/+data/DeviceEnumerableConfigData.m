classdef DeviceEnumerableConfigData
    %DEVICEENUMERABLECONFIGDATA Applet data specific to a Hardware Manager device

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)

        % Client app applet class inheriting from matlab.hwmgr.internal.AppletBase
        AppletClass

        % App and Device specific DeviceDescriptor class inherting from matlab.hwmgr.internal.DeviceParamsDescriptor
        EnumerableDeviceDescriptor

    end

    properties

        % Boolean to convey whether configuration is required
        NeedsConfiguration
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase, ?matlab.hwmgr.internal.DeviceParamsDescriptor})

        function obj = DeviceEnumerableConfigData(appletClass, enumerableDeviceDescriptor, needsConfiguration)
            arguments
                appletClass (1, 1) string
                enumerableDeviceDescriptor (1, 1) string
                needsConfiguration (1,1) logical
            end

            obj.AppletClass = appletClass;
            obj.EnumerableDeviceDescriptor = enumerableDeviceDescriptor;  
            obj.NeedsConfiguration = needsConfiguration;
        end
    end
end
