classdef LiveEditorWidgetRegistryUpdater < internal.matlab.datatoolsservices.WidgetRegistrator
   
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class registers the LiveEditorServerWidgetRegistry.JSON file to
    % the WidgetRegistry.m that creates a map and uses these entries to
    % provide views/editors/renderers for the Live Editor.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties(Constant)
        JSONDefaultsFilePath = fullfile(toolboxdir('matlab'),'codetools', ...
        'embeddedoutputs','DataToolsRegistration','LiveEditorServerWidgetRegistry.JSON');
    end
    
    methods(Static)
        function [filePath] = getWidgetRegistrationFile()
            filePath = datatoolsservices.internal.widgetregistry.LiveEditorWidgetRegistryUpdater.JSONDefaultsFilePath;
        end
    end
end