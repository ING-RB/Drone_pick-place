classdef SidePanelMixin < handle
    % Client app mixin class for creating and removing side panels to and
    % from the main AppContainer window.

    % Copyright 2022 Mathworks Inc

    properties (Abstract, Access = protected)
        AppContainer
    end

    methods

        function sidePanel = createSidePanel(obj, panelOptions)
            % This method can be called to create a side panel. The method
            % returns a uipanel inside the side panel. For panelOptions,
            % see the properties of matlab.ui.internal.FigurePanel

            arguments
                obj
                panelOptions = struct('PermissibleRegions', 'right', ...
                    'Region', 'right', ...
                    'Collapsible', true, ...
                    'Closable', false, ...
                    'Maximizable', false, ...
                    'Title', 'Test Panel');
            end

            panelOptions = matlab.hwmgr.internal.SidePanelMixin.checkPanelOptions(panelOptions);

            figPanel = matlab.ui.internal.FigurePanel(panelOptions);
            grid = uigridlayout(figPanel.Figure, [1,1]);
            sidePanel = uipanel(grid);
            obj.AppContainer.add(figPanel);

        end

        function removeSidePanel(obj, identifier)
            % This method can be called to remove a side panel. IDENTIFIER
            % is the side panel title or tag
            obj.AppContainer.removePanel(identifier);
        end

        function setSidePanelProperty(obj, identifier, propName, propValue)
            % This method allows downstream teams to set a particular
            % property of a figure panel
            arguments
                obj
                identifier (1, 1) string
                propName (1, 1) string
                propValue
            end

            figurePanel = obj.AppContainer.getPanel(identifier);
            figurePanel.(propName) = propValue;
        end
    end

    methods (Static, Access = ?hwmgr.test.internal.TestCase)

        function panelOptions = checkPanelOptions(panelOptions)

            % Ensure that the panel isn't going to be in the place of
            % the device list
            if isfield(panelOptions, 'PermissibleRegions') && any(strcmpi(string(panelOptions.PermissibleRegions),"left")) || ...
                    isfield(panelOptions, 'Region') &&  (strcmpi(string(panelOptions.Region),"left"))
                error(message('hwmanagerapp:framework:LeftSidePanelDisallowed'));
            end

            % If the panel options dont have region and permissible
            % region specified, give default values
            if ~isfield(panelOptions, 'PermissibleRegions')
                panelOptions.PermissibleRegions = "right";
            end

            if ~isfield(panelOptions, 'Region')
                panelOptions.Region = "right";
            end

        end

    end

end