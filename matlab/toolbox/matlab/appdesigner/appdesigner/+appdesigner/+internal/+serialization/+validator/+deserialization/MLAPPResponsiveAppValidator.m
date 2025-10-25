classdef MLAPPResponsiveAppValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPAppTypeValidator Validator for responsive app's layout type
    % 19a only supports 2-region or 3-region layout type, which is
    % decided by the responsive container - GridLayout's row/column
    % number

    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function validateAppData(obj, metadata, appData)
            % In 19a, the responsive app supports 2-region and 3-region
            % layout type. The component hierarchay for these two
            % responsive apps:
            % uifigure->GridLayout-> two or three Panels
            % GridLayout and Panels have a property 'IsResponsiveContainer'
            % in DesignTimeProperties
            % The validation is check these facts to determin if it's a
            % supported responsive layout type.

            errorMsg = message('MATLAB:appdesigner:appdesigner:IncompatibleAppVersion', metadata.MinimumSupportedMATLABRelease);

            if strcmp(appdesigner.internal.serialization.app.AppTypes.ResponsiveApp, metadata.AppType)
                % Find responsive container: GridLayout
                components = findall(appData.components.UIFigure, '-depth',1, '-and', ...
                    '-property', 'DesignTimeProperties', '-and', ...
                    'Type', 'uigridlayout');

                grid = [];
                for i = 1:numel(components)
                    comp = components(i);
                    if isfield(comp.DesignTimeProperties, 'AppTypeProperties') && ...
                            isfield(comp.DesignTimeProperties.AppTypeProperties, 'IsResponsiveContainer') && ...
                            comp.DesignTimeProperties.AppTypeProperties.IsResponsiveContainer == true

                        % A responsive container GridLayout has already been
                        % found and set in previous loop, and now another one
                        % is found, which is invalid to have more than one
                        % GridLayout as a responsive container
                        if ~isempty(grid)
                            error(errorMsg);
                        end

                        grid = comp;
                    end
                end

                % No responsive container GridLayout found
                if isempty(grid)
                    error(errorMsg);
                end

                % Layout type is not supported, which should be a one row
                % and two or three columns
                if ~(numel(grid.RowHeight) == 1 && ...
                        (numel(grid.ColumnWidth) == 2  || ...
                        numel(grid.ColumnWidth) == 3))
                    error(errorMsg);
                end
            end
        end
    end
end

