classdef AppSpaceElementsFactory
    %APPSPACEELEMENTSFACTORY is a factory class containing static methods
    %that helps construct the AppSpace section View. It provides API's for
    %creating AppSpace UI Elements like uigridlayout, uipanels, etc.

    % Copyright 2020-2024 The MathWorks, Inc.

    %% Private Constructor
    methods (Access = private)
        function obj = AppSpaceElementsFactory()
        end
    end

    %% Factory Methods
    methods (Static)
        function gridLayout = createGridLayout(parent, properties)
            % Create a grid layout.
            % parent - Parent of the grid layout
            % properties - property-value set for the grid layout
            arguments
                parent
                properties struct
            end

            gridLayout = uigridlayout(parent);
            gridLayout = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(gridLayout, properties);
        end

        function panel = createPanel(parent, layout, properties)
            % Create a uipanel.
            % parent - Parent of the uipanel
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the panel in the parent uigridlayout
            % properties - property-value set for the uipanel
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end

            panel = uipanel(parent);

            panel = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(panel, layout);
            panel = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(panel, properties);
        end

        function table = createTable(parent, layout, properties)
            % Create a ui table with the capability to select a single row.
            % parent - Parent of the uitable
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the uitable in the parent uigridlayout
            % properties - property-value set for the uitable

            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end

            table = uitable(parent, 'SelectionType', 'row', 'Multiselect', false);
            table = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(table, layout);
            table = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(table, properties);
        end

        function propInspector = ...
                createPropertyInspector(parent, layout, properties)
            % Create a property inspector section
            % parent - Parent of the property inspector
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the property inspector panel in the parent uigridlayout
            % properties - property-value set for the property inspector
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end

            propInspector = ...
                matlab.ui.control.internal.Inspector( ...
                Parent = parent, ...
                UseLabelForReadOnly = true, ... % Read-Only properties show up as UI-Labels
                SupportsPopupWindowEditor = false, ... % Disable the pencil-icon for settable properties
                ShowInspectorToolstrip = false ... % Disable the property inspector toolstrip that contains the search and sort options
                );
            propInspector = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(propInspector, layout);
            propInspector = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(propInspector, properties);
        end

        function contextMenu = ...
                createContextMenu(parent, tableHandle)
            % Create a uicontextmenu for the given tableHandle
            % parent - Parent figure of the context menu
            % tableHandle - The handle to the uitable for which the context
            %               menu is being created.
            arguments
                parent
                tableHandle
            end

            contextMenu = uicontextmenu(parent);
            tableHandle.ContextMenu = contextMenu;
        end

        function menu = createMenu(parent, menuItems, fcnHandles)
            % Create a uimenu for the given context menu
            % parent - Parent uicontextmenu
            % menuItems - The list of menus to be created.
            % fcnHandles - The list of function handles associated with
            %              each menu. This function handle gets invoked
            %              whenever the menu is clicked.
            arguments
                parent
                menuItems (1, :) string {mustBeNonempty}
                fcnHandles (1, :) cell
            end

            menu = matlab.ui.container.Menu.empty();
            for i = 1 : length(menuItems)
                menu(end+1) = uimenu(parent, "Text", menuItems(i), "MenuSelectedFcn", fcnHandles{i}); %#ok<AGROW>
            end
        end

        function uihtmlInstance = createUIHTML(parent, layout, properties)
            % Create a UI HTML page
            % parent - Parent of the uihtml
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the panel in the parent uigridlayout
            % properties - property-value set for the uihtml
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end

            uihtmlInstance = uihtml(parent);
            matlab.ui.internal.HTMLUtils.enableTheme(uihtmlInstance);
            uihtmlInstance = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(uihtmlInstance, layout);
            uihtmlInstance = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(uihtmlInstance, properties);
        end

        function sidePanel = createHwMgrSidePanel(appletObj, panelProperties)
            % Create a hardware manager side panel.
            % appletObj - The AppletBase class that has access to the side
            %             panel provided by HwMgr.
            % panelProperties - property-value set for the hwmgr side
            %                   panel.
            arguments
                appletObj matlab.hwmgr.internal.AppletBase
                panelProperties (1, 1) struct
            end

            sidePanel = appletObj.createSidePanel(panelProperties);

            % Update changes to the parent UIGridLayout for the side-panel.
            sidePanelParentGrid = sidePanel.Parent;
            sidePanelParentGrid.RowSpacing = 0;
            sidePanelParentGrid.ColumnSpacing = 0;
            sidePanelParentGrid.Padding = 0;
        end

        function label = createLabel(parent, layout, properties)
            % Create a UILABEL
            % parent - Parent of the uilabel
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the label in the parent uigridlayout
            % properties - property-value set for the uilabel
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end
            label = uilabel(parent);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(label, layout);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(label, properties);
        end

        function editField = createEditField(parent, layout, properties)
            % Create an UIEDITFIELD
            % parent - Parent of the uieditfield
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the edit field in the parent uigridlayout
            % properties - property-value set for the uieditfield
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end
            editField = uieditfield(parent);
            editField = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(editField, layout);
            editField = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(editField, properties);
        end

        function label = createButton(parent, layout, properties)
            % Create a UIBUTTON
            % parent - Parent of the uibutton
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the button in the parent uigridlayout
            % properties - property-value set for the uibutton
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end
            label = uibutton(parent);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(label, layout);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(label, properties);
        end

        function label = createTextArea(parent, layout, properties)
            % Create a UITEXTAREA
            % parent - Parent of the uitextarea
            % layout - If the parent is a uigridlayout, the layout structure
            %          for the text area in the parent uigridlayout
            % properties - property-value set for the uitextarea
            arguments
                parent
                layout matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
                properties struct
            end
            label = uitextarea(parent);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setGridLayout(label, layout);
            label = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.setProperties(label, properties);
        end
    end

    %% Helper Functions
    methods (Access = private, Static)
        function element = setGridLayout(element, layout)
            % For a uigridlayout parent, set the element's layout structure
            % on the parent grid.
            if ~isempty(layout)
                element.Layout.Row = layout.Row;
                element.Layout.Column = layout.Column;
            end
        end

        function element = setProperties(element, properties)
            % Assign property values to the appspace UI Elements.
            if ~isempty(properties)

                for propertyName = string(fieldnames(properties))'
                    element.(propertyName) = properties.(propertyName);
                end
            end
        end
    end
end
