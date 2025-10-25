classdef MWTableRegistrator < internal.matlab.datatoolsservices.WidgetRegistrator
    %MWTableRegistrator  Class for Web Widget Registration
    % Registers UITable Widget Defaults

    % Copyright 2018 The MathWorks, Inc.
    properties(Constant)
        JSONDefaultsFilePath = fullfile(matlabroot, 'toolbox','matlab','uitools','componentsjs','controller','utils','UITableWidgetRegistryDefaults.JSON');
    end
    
    methods(Static)
        function [filePath] = getWidgetRegistrationFile()
            filePath = datatoolsservices.internal.widgetregistry.MWTableRegistrator.JSONDefaultsFilePath;
        end
    end
end
