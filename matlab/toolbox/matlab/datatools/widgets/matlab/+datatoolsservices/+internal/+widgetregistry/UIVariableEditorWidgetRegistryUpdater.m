classdef UIVariableEditorWidgetRegistryUpdater < internal.matlab.datatoolsservices.WidgetRegistrator
   
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class registers the UIVariableEditorWidgetRegistryUpdater.JSON file to
    % the WidgetRegistry.m that creates a map and uses these entries to
    % provide views/editors/renderers for the Variable Editor.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Constant)
        JSONDefaultsFilePath = fullfile(toolboxdir('matlab'),'datatools', ...
        'widgets','matlab','+datatoolsservices','+internal','+widgetregistry','UIVariableEditorServerPlugins.JSON');
    end
    
    methods(Static)
        function [filePath] = getWidgetRegistrationFile()
            filePath = datatoolsservices.internal.widgetregistry.UIVariableEditorWidgetRegistryUpdater.JSONDefaultsFilePath;
        end
    end
end