classdef HelpDocLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    %HelpDocLaunchable This class is responsible for launching help documentation.

    % Copyright 2024 The MathWorks, Inc.

    properties (Access = ?matlab.unittest.TestCase)
        HelpDocLink   % The doc link data containing documentation to be viewed
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = HelpDocLaunchable(launchableData, ~, varargin)
            obj.HelpDocLink = launchableData.HelpDocLink;
        end
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        function launch(obj)
            matlab.hwmgr.internal.util.launchHelp(obj.HelpDocLink);
        end
    end
end
   