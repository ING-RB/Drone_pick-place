function defaultsRestorer = overrideCustomAppBuildingDefaults(grootOrFigOrCompContainer, defaultNamesToOverride)
    % Triggering custome default CreateFcn & FigureColor is not expected in App Designer on
    % components, so this function is to override custom CreateFcn on groot or a uifigure
    % or a ComponentContainer object

    % Copyright 2022 - 2023 The MathWorks, Inc.

    defaultsRestorer = [];

    if nargin == 0
        grootOrFigOrCompContainer = groot;
    end

    if nargin < 2
        % For now, by default only override CreateFcn & FigureColor && FigureWindowStyle (dock is not supported yet) custom defaults
        % Probably in the future, we can try to apply all factory defaults and 
        % fix issues uncovered        
        defaultNamesToOverride = ["CreateFcn", "FigureColor", "FigureWindowStyle"];
    end

    defaults = get(groot, 'default');
    defaultNames = fieldnames(defaults);
    for d = 1:numel(defaultNames)
        defaultName = defaultNames{d};
        if endsWith(defaultName, defaultNamesToOverride)
            if isa(grootOrFigOrCompContainer, "matlab.ui.Root")
                % Need to restore custom defaults on groot at the end
                originalDefaultValue = get(groot, defaultName);

                % Cleanup to restore the default
                cleanupObj = onCleanup(@()  set(groot, defaultName, originalDefaultValue));
                defaultsRestorer = [defaultsRestorer cleanupObj];
            end

            % Override with factory default value
            factoryName = strrep(defaultName, 'default', 'factory');
            set(grootOrFigOrCompContainer, defaultName, get(groot, factoryName));
        end
    end
end