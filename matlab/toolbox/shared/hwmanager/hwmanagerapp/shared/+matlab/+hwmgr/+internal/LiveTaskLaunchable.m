classdef LiveTaskLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    %LIVETASKLAUNCHABLE This class is responsible for launching Live Editor Tasks.

    % Copyright 2024 The MathWorks, Inc.

     properties (Access = ?matlab.unittest.TestCase)
        HwmgrDevice
        EntryPoint
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = LiveTaskLaunchable(launchableData, selectedDevice, varargin)
            obj.EntryPoint = launchableData.EntryPoint;
            obj.HwmgrDevice = selectedDevice;
        end
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        function launch(obj)
            feval(obj.EntryPoint, obj.HwmgrDevice);
        end
    end
end