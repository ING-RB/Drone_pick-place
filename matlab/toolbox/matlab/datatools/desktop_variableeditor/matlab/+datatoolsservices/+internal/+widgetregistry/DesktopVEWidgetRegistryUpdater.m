classdef DesktopVEWidgetRegistryUpdater < internal.matlab.datatoolsservices.WidgetRegistrator
   
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class registers the VEServerWidgetRegistry.JSON file to
    % the WidgetRegistry.m that creates a map and uses these entries to
    % provide views/editors/renderers for the Variable Editor.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties(Constant)
        JSONDefaultsFilePath = fullfile(toolboxdir('matlab'),'datatools', ...
        'desktop_variableeditor','matlab','DesktopVEServerWidgetRegistry.JSON');
    end
    
    methods(Static)
        function [filePath] = getWidgetRegistrationFile()
            filePath = datatoolsservices.internal.widgetregistry.DesktopVEWidgetRegistryUpdater.JSONDefaultsFilePath;
        end
    end
end