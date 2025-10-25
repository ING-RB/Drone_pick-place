function componentMetadata = getComponentMetaData(componentAdapterMap)
    % GETCOMPONENTMETADATA retrieve the component initialization data required by the client

    % create an empty component metadata struct

    %   Copyright 2015-2024 The MathWorks, Inc.

    componentMetadata = struct.empty;

    % retrieve the list of adapters from the map
    adapterFileNames = values(componentAdapterMap);

    % Use these flags instead of AutomaticFigureThemesInJSD because
    % these flags will work in Java MATLAB as well & the defaults are build in Java MATLAB.
    automaticThemes = feature('AutomaticFigureThemes');
    figureThemes = feature('FigureThemesEnabled');
    s = settings;
    hasTempSetting = hasTemporaryValue(s.matlab.appearance.figure.GraphicsTheme);
    settingTheme = s.matlab.appearance.figure.GraphicsTheme.ActiveValue;

    % iterate over the adapter file names and create a structure of component data
    for j=1:length(adapterFileNames)
        adapterFileName = adapterFileNames{j};
        adapterInstance = eval(adapterFileName);

        % create a structure holding component metadata for each
        % component type.  The metadata is the component default
        % values retrieved via the component adapter
        componentMetadata(end+1).Type = adapterInstance.ComponentType;

        % Turn off the feature to get the unthemed defaults
        feature('AutomaticFigureThemes', 0);
        feature('FigureThemesEnabled', 0);
        componentMetadata(end).DefaultValues.unthemed = adapterInstance.getComponentDesignTimeDefaults();

        % Turn on the feature to get the themed defaults
        feature('AutomaticFigureThemes', 1);
        feature('FigureThemesEnabled', 1);

        s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';
        componentMetadata(end).DefaultValues.light = adapterInstance.getComponentDesignTimeDefaults();

        s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'dark';
        componentMetadata(end).DefaultValues.dark = adapterInstance.getComponentDesignTimeDefaults();

        componentMetadata(end).DefaultValues = removeCommonProperties(componentMetadata(end).DefaultValues);

        componentMetadata(end).JavaScriptAdapter = adapterInstance.getJavaScriptAdapter();
        componentMetadata(end).MATLABAdapter = adapterFileName;
        componentMetadata(end).DocString = adapterInstance.getDocString();
    end

    feature('AutomaticFigureThemes', automaticThemes);
    feature('FigureThemesEnabled', figureThemes);
    if hasTempSetting
        s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = settingTheme;
    else
        clearTemporaryValue(s.matlab.appearance.figure.GraphicsTheme);
    end

    function defaultValues = removeCommonProperties(defaultValues)
        unthemedDefaults = fieldnames(defaultValues.unthemed);

        % Iterate through fieldnames and remove common properties
        for i = 1:numel(unthemedDefaults)
            fieldname = unthemedDefaults{i};

            % Check if the field exists in light & dark struct and matches unthemed
            themes = {'light', 'dark'};

            for k = 1:length(themes)
                if isfield(defaultValues.(themes{k}), fieldname) && isequal(defaultValues.(themes{k}).(fieldname), defaultValues.unthemed.(fieldname))
                    defaultValues.(themes{k}) = rmfield(defaultValues.(themes{k}), fieldname);
                end
            end
        end
    end
end

