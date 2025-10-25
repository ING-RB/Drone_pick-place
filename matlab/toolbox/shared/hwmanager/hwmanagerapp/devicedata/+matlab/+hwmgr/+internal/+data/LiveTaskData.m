classdef LiveTaskData < matlab.hwmgr.internal.data.LaunchableData
    %LIVETASKDATA Live task data required by Hardware Manager app

    % Copyright 2022-2024 The MathWorks, Inc.

    properties %(SetAccess = private)
        %LiveTaskDisplayName
        %   Live task customer visible name
        LiveTaskDisplayName

        %EntryPoint
        %   Path to the live script for the live task, is used with "run"
        EntryPoint

        %PluginClass
        %   Live task plugin class inheriting from matlab.hwmgr.internal.plugins.PluginBase
        PluginClass
    end

    methods %(Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = LiveTaskData(liveTaskDisplayName, entryPoint, pluginClass, ...
                description, iconID, learnMoreLink, ...
                identifier, nameValueArgs)
            arguments
                liveTaskDisplayName (1, 1) string
                entryPoint (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                identifier (1, 1) string = ""
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
            end

            namedArgsCell  = namedargs2cell(nameValueArgs);

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.LiveTask, ...
                                                          liveTaskDisplayName, ...
                                                          description, ...
                                                          iconID, learnMoreLink, ...
                                                          message('hwmanagerapp:hwmgrstartpage:OpenLiveTask').getString(), ...
                                                          namedArgsCell{:});
            % Initialize this class properties
            obj.LiveTaskDisplayName = liveTaskDisplayName;
            obj.EntryPoint = entryPoint;
            obj.PluginClass = pluginClass;
        end
    end
end
