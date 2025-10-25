classdef DeviceListModuleInfo < matlab.ui.container.internal.appcontainer.ModuleInfo
    %DEVICELISTMODULEINFO ModuleInfo for Device List Panel JS module

    % Copyright 2022 The MathWorks, Inc.
    
    methods
        function obj = DeviceListModuleInfo()
            % Path to module (relative to MATLAB root)
            obj.Path = "/toolbox/shared/hwmanager/hwmanagerapp/web/clientapp/clientapp-startpage-ui/clientapp-startpage-ui";
            
            % Class(es) exported by module
            obj.Exports = "DeviceListPanelFactory";

            % Path to dependencies file (relative to MATLAB root)
            obj.DebugDependenciesJSONPath = "/toolbox/shared/hwmanager/hwmanagerapp/web/clientapp/clientapp-startpage-ui/js_dependencies.json";
        end
    end
end

