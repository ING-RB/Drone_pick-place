classdef InspectorWidgetRegistryUpdater < internal.matlab.datatoolsservices.WidgetRegistrator

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class registers the InspectorWidgetRegistryDefaults.JSON file to
    % the WidgetRegistry.m that creates a map and uses these entries to
    % provide views/editors/renderers for the inspector.

    % Copyright 2019 The MathWorks, Inc.

    properties(Constant)
        JSONDefaultsFilePath = fullfile(toolboxdir('matlab'),'datatools', ...
            'inspector','matlab','+internal','+matlab', '+inspector', 'InspectorWidgetRegistryDefaults.JSON');
    end

    methods(Static)
        function [filePath] = getWidgetRegistrationFile()
            filePath = datatoolsservices.internal.widgetregistry.InspectorWidgetRegistryUpdater.JSONDefaultsFilePath;
        end
    end
end

