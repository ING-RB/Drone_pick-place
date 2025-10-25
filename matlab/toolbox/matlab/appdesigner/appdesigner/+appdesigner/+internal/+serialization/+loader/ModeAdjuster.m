classdef ModeAdjuster < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    % ModeAdjuster  A class used when loading an App Designer file to reset
    % modes to auto when their related themed properties have default values but their corresponding mode is manual.

    % Copyright 2024 The MathWorks, Inc.

    properties (Constant)
        UnthemedDefaults = dictionary(...
            "matlab.ui.Figure", struct('Color', [0.9400 0.9400 0.9400]), ...
            "matlab.ui.container.ButtonGroup", struct('BackgroundColor', [0.9400 0.9400 0.9400], 'ForegroundColor', [0 0 0], 'HighlightColor', [0.4902 0.4902 0.4902], 'ShadowColor', [0.7000 0.7000 0.7000]), ...
            "matlab.ui.container.Menu", struct('ForegroundColor', [0 0 0]), ...
            "matlab.ui.container.Panel", struct('BackgroundColor', [0.9400 0.9400 0.9400], 'ForegroundColor', [0 0 0], 'HighlightColor', [0.4902 0.4902 0.4902], 'ShadowColor', [0.7000 0.7000 0.7000]), ...
            "matlab.ui.container.Tab", struct('BackgroundColor', [0.9400 0.9400 0.9400], 'ForegroundColor', [0 0 0]), ...
            "matlab.ui.container.Toolbar", struct('BackgroundColor', [0.9569 0.9569 0.9569]), ...
            "matlab.ui.control.Table", struct('BackgroundColor', [[1 1 1]; [0.9400 0.9400 0.9400]], 'ForegroundColor', [0 0 0]), ...
            "matlab.ui.componentcontainer.ComponentContainer", struct('BackgroundColor', [0.9400 0.9400 0.9400]), ...
            "matlab.ui.control.UIAxes", struct('GridAlpha', 0.15, 'MinorGridAlpha', 0.25, 'Color', [1 1 1], 'XColor', ...
            [0.1500 0.1500 0.1500], 'YColor', [0.1500 0.1500 0.1500], 'ZColor', [0.1500 0.1500 0.1500], ...
            'GridColor', [0.1294 0.1294 0.1294], 'MinorGridColor', [0.1294 0.1294 0.1294],  ...
            'ColorOrder', [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560]; ...
            [0.4660 0.6740 0.1880]; [0.3010 0.7450 0.9330]; [0.6350 0.0780 0.1840]]));
    end

    methods

        function obj = ModeAdjuster(loader)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
        end

        function appData = load(obj)
            appData = obj.Loader.load();
            obj.resetModes(appData.components.UIFigure);
        end

    end

    methods (Access=private)
        function roundedValue = roundIfNumeric(~, inputValue, precision)
            % Check if inputValue is numeric and can be rounded
            if isnumeric(inputValue)
                roundedValue = round(inputValue, precision);
            else
                % leave value as it is if cannot be rounded
                roundedValue = inputValue;
            end
        end

        function resetModes(obj, component)
            if (isa(component, 'matlab.ui.componentcontainer.ComponentContainer'))
                componentType = 'matlab.ui.componentcontainer.ComponentContainer';
            else
                componentType = class(component);
            end

            if (obj.UnthemedDefaults.isKey(componentType))

                props = fieldnames(obj.UnthemedDefaults(componentType));

                for i = 1:numel(props)
                    % only consider themed properties
                    defaultValue = obj.roundIfNumeric(obj.UnthemedDefaults(componentType).(props{i}), 4);
                    value = obj.roundIfNumeric(component.(props{i}), 4);
                    modeName = [props{i}, 'Mode'];

                    isDefaultValue = isequal(value, defaultValue);

                    % If value is default & mode is not auto, reset the mode to auto 
                    if isDefaultValue && isprop(component, modeName) && ~isequal(component.(modeName), 'auto')
                        component.(modeName) = 'auto';
                    end
                end
            end

            % Recursively handle child components.  Do not want to iterate
            % over the Axes children/UACs because they are not components
            if (isprop(component, 'Children')) && ~isa(component, 'matlab.ui.control.UIAxes') && ...
                ~isa(component, 'matlab.ui.componentcontainer.ComponentContainer')
                children = allchild(component);
                for i = 1:length(children)
                    obj.resetModes(children(i));
                end
            end
        end
    end
end