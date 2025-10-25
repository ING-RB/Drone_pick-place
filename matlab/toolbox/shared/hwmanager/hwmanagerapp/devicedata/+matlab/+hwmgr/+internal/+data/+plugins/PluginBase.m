classdef PluginBase < handle
    %PLUGINBASE Hardware Manger data plugin base class

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %HardwareKeywordData
        %   Data on hardware keyword entries.
        HardwareKeywordData (1, :) matlab.hwmgr.internal.data.HardwareKeywordData

        %AppletData
        %   Data on client apps.
        AppletData (1, :) matlab.hwmgr.internal.data.AppletData

        %AddOnData
        %   Data on toolboxes support packages
        AddOnData (1, :) matlab.hwmgr.internal.data.AddOnData

        %LiveTaskData
        %   Data on live tasks
        LiveTaskData (1, :) matlab.hwmgr.internal.data.LiveTaskData

        %HardwareSetupData
        %   Data on Hardaware Setup entries
        HardwareSetupData (1, :) matlab.hwmgr.internal.data.HardwareSetupData

        %ExampleData
        %   Data representing Example entries for launching examples
        ExampleData (1, :) matlab.hwmgr.internal.data.ExampleData

        %SimulinkModelData
        %   Data representing Simulink Model entries for launching Simulink Models
        SimulinkModelData (1, :) matlab.hwmgr.internal.data.SimulinkModelData

        %HelpDocData
        %   Data representing documentation entries for launching documentation pages
        HelpDocData (1, :) matlab.hwmgr.internal.data.HelpDocData

    end

    methods
        function addHardwareKeywordData(obj, hardwareKeywordData)
            obj.HardwareKeywordData = [obj.HardwareKeywordData, hardwareKeywordData];
        end

        function addAppletData(obj, appletData)
            obj.AppletData = [obj.AppletData, appletData];
        end

        function addAddOnData(obj, addOnData)
            obj.AddOnData = [obj.AddOnData, addOnData];
        end

        function addLiveTaskData(obj, liveTaskData)
            obj.LiveTaskData = [obj.LiveTaskData, liveTaskData];
        end

        function addHardwareSetupData(obj, hardwareSetupData)
            obj.HardwareSetupData = [obj.HardwareSetupData, hardwareSetupData];
        end

        function addExampleData(obj, exampleData)
            obj.ExampleData = [obj.ExampleData, exampleData];
        end

        function addSimulinkModelData(obj, simulinkModelData)
            obj.SimulinkModelData = [obj.SimulinkModelData, simulinkModelData];
        end

        function addHelpDocData(obj, helpDocData)
            obj.HelpDocData = [obj.HelpDocData, helpDocData];
        end
    end
end
