classdef DatatoolsDefaults < internal.matlab.datatoolsservices.WidgetRegistrator
    %DatatoolsDefaults Default Web Widget Registration
    %

    % Copyright 2018 The MathWorks, Inc.
    properties (Constant)
        DefaultsPath = fullfile(matlabroot,'toolbox','matlab','datatools','datatoolsservices','js','datatoolsservices','src');
        DefaultsFile = 'WidgetRegistryDefaults.JSON';
    end
    
    methods(Static = true)
        function [filePath] = getWidgetRegistrationFile()
            import internal.matlab.datatoolsservices.widgetregistry.DatatoolsDefaults;
            filePath = fullfile(DatatoolsDefaults.DefaultsPath,...
                DatatoolsDefaults.DefaultsFile);
        end
    end
end

