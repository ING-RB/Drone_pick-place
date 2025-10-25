classdef Controller < ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource 

    %CONTROLLER is the Appspace Communication Log Controller Class. It
    %contains business logic for operations that need to be performed when
    %user interacts with the table.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Dependent)
        TableHandle
        View
    end

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable, ...
            ?matlabshared.transportapp.internal.appspace.communicationlog.Controller})
        ViewConfiguration

        %% Table Cell styles
        % For error color
        TableStyleErrorColor = matlab.ui.style.internal.SemanticStyle("FontColor", "--mw-color-error")

        % For bold text
        TableStyleBoldText = uistyle(FontWeight="bold")

        %% Listeners
        % When the table data changes
        TableDataListener = event.listener.empty

        % When the table selected row changes
        CellSelectionListener = event.listener.empty

        % RawTableData contains the ultimate truth of the data written/read
        % using the app. It is an array of utilities.forms.TableRowData. All
        % conversions based on the display type, conversion to table type,
        % conversion to timetable type, happens using the RawTableData.
        RawTableData (1,:) = ...
            matlabshared.transportapp.internal.utilities.forms.TableRowData.empty

        % The display type set in the toolstrip communications log section.
        DisplayType (1,1) string = "Default"

        % Flag to run the controller in production mode or unit-test mode
        ProductionMode (1, 1) logical = false

        % The right click context menu for the table.
        ContextMenu

        % The context menu text items.
        MenuItems
    end

    properties (SetObservable)
        TableValue
        SelectedRowData
        ExportSuccessful (1,1) logical = false
        ExportMenuItemPressed
    end

    properties
        Constants
        TableRowData
    end

    %% Hook Methods
    methods
        function constants = getConstants(~)
            % This hook method may be overridden by subclasses to provide a
            % custom controller constants class.
            constants = matlabshared.transportapp.internal.appspace.communicationlog.Constants;
        end

        function tableRowData = getTableRowData(~)
            % This hook method may be overridden by subclasses to provide a
            % custom TableRowData
            tableRowData = matlabshared.transportapp.internal.utilities.forms.TableRowData;
        end
    end

    %% Lifetime
    methods
        function obj = Controller(mediator, viewConfiguration, ~)
            arguments
                mediator matlabshared.mediator.internal.Mediator
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
                ~
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(mediator);

            obj.Constants = obj.getConstants();
            obj.TableRowData = obj.getTableRowData();
            obj.RawTableData = obj.TableRowData.empty;
            obj.ViewConfiguration = viewConfiguration;
            obj.ProductionMode = isa(obj.ViewConfiguration, ...
                "matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration");

            % Only for production mode
            if obj.ProductionMode
                obj.setupListeners();
            end
        end

        function connect(obj)
            % Set up the listener for whenever the table data changes.
            obj.TableDataListener = listener( ...
                obj.TableHandle,'Data','PostSet',@(src, evt)obj.handleTableDataChanged(src, evt));
        end

        function disconnect(obj)
            delete(obj.TableDataListener);
        end

        function delete(obj)
            delete(obj.CellSelectionListener);
            delete(obj.MenuItems);
            delete(obj.ContextMenu);
        end
    end

    %% Implement matlabshared.mediator.internal.Subscriber abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe("ClearTable", ...
                @(src, event)obj.clearTable());

            obj.subscribe("CommunicationLogData", ...
                @(src, event)obj.handleCommunicationLogData(event.AffectedObject.CommunicationLogData));

            obj.subscribe("DisplayType", ...
                @(src, event)obj.handleDisplayTypeChanged(event.AffectedObject.DisplayType));

            obj.subscribe("ExportCommLog", ...
                @(src, event)obj.exportCommunicationLog(event.AffectedObject.ExportCommLog));
        end
    end

    %% Subscriber Handler Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function tableIndexSelected(obj, ~, evt)
            % Handler for when the user selects a row of the communication
            % log table.

            obj.SelectedRowData = obj.RawTableData(evt.Data);
        end

        function handleTableDataChanged(obj, ~, ~)
            % Handler for when the table data changes. The TableValue
            % property is subscribed to by the various toolstrip controller
            % classes that need to be notified when the table data changes.

            obj.TableValue = obj.TableHandle.Data;
        end

        function exportCommunicationLog(obj, varName)
            % Convert the table's RawTableData into a timetable and export
            % this timetable into the base MATLAB workspace. The MATLAB
            % Workspace Variable name to which the timetable is exported to
            % is passed in from the toolstrip export section.

            arguments
                obj
                varName (1, 1) string
            end

            try
                % Get the timetable data from the RawTableData.
                timeTableData = obj.TableRowData.convertFormToTimeTable(obj.RawTableData);

                % Using the WorkspaceVariableHandler utility function, save
                % the data to the base MATLAB workspace.
                matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler. ...
                    setVariableInMatlabWorkspace(varName, timeTableData);

                % Notify the toolstrip export section that the export has
                % been completed successfully.
                obj.ExportSuccessful = true;
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function clearTable(obj)
            % When the event for a clear table happens
            % 1. clear the table data
            % 2. clear the table data and selected row
            % 3. clear the table focus
            % 4. clear the RawTableData.
            % 5. remove the uistyle from the table

            obj.TableHandle.Data = [];
            obj.SelectedRowData = [];
            obj.clearTableFocus();
            obj.RawTableData = obj.TableRowData.empty;
            obj.clearTableContextMenu();
            removeStyle(obj.TableHandle);
        end

        function handleCommunicationLogData(obj, logData)
            % Handler for when there is new data to be displayed in the
            % table.
            arguments
                obj
                logData
            end

            if isempty(obj.RawTableData)
                obj.createTableContextMenu();
            end

            % Append the original data read/written TableRowData to the
            % RawTableData
            obj.RawTableData = [obj.RawTableData, logData];

            % Get the new converted display for this new row of table data.
            newRow = obj.getUpdatedDisplayForm(logData);

            % Now, convert this newly converted display TableRowData into a
            % table.
            tableData = obj.TableRowData.convertFormToTable(newRow);

            % Append the created table data to existing data in the
            % Communication Log table.
            obj.TableHandle.Data = [obj.TableHandle.Data; tableData];

            % If the row is an error row, format the error row.
            if logData.ErrorRow && obj.ProductionMode
                errorRowIndex = length(obj.RawTableData);
                obj.formatError(errorRowIndex);
            end

            if obj.ProductionMode
                scroll(obj.TableHandle, "bottom");
            end

            obj.clearTableFocus();

            % Set the selected row to the last added row.
            obj.TableHandle.Selection = size(obj.TableHandle.Data, 1);
            obj.SelectedRowData = obj.RawTableData(end);
        end

        function handleDisplayTypeChanged(obj, displayType)
            % Handler for when the Display type changes in the toolstrip
            % communication log section.

            obj.DisplayType = displayType;
            displayForm = getUpdatedDisplayForm(obj, obj.RawTableData);
            data = obj.TableRowData.convertFormToTable(displayForm);
            obj.TableHandle.Data = data;
        end
    end

    %% Helper Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function formatError(obj, indices)
            try
                for index = indices
                    addStyle(obj.TableHandle, obj.TableStyleErrorColor, "cell", [index, obj.Constants.DataColumn]);
                    addStyle(obj.TableHandle, obj.TableStyleBoldText, "cell", [index, obj.Constants.DataColumn]);
                end
            catch
            end
        end

        function clearTableFocus(obj)
            % Reset the last table row selected by setting the following
            % table properties.

            obj.TableHandle.Multiselect = "on";
            obj.TableHandle.SelectionType = "cell";

            obj.TableHandle.SelectionType = "row";
            obj.TableHandle.Multiselect = "off";
        end

        function formData = getUpdatedDisplayForm(obj, form)
            % Get a converted TableRowData instance from the TableRowData
            % instance passed in. The conversion happens based on the
            % Display Type selected by the user in the toolstrip
            % communication log section.

            arguments
                obj
                form
            end

            switch obj.DisplayType
                case "Default"
                    formData = form;
                case "Binary"
                    formData = obj.TableRowData.convertToBinary(form);
                case "ASCII"
                    formData = obj.TableRowData.convertToASCII(form);
                case "Hexadecimal"
                    formData = obj.TableRowData.convertToHex(form);
            end
        end

        function createTableContextMenu(obj)
            % Creates the right-click context menu for the communication
            % log table.

            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory

            if obj.ProductionMode
                parent = obj.TableHandle;

                while ~isa(parent, "matlab.ui.Figure")
                    parent = parent.Parent;
                end

                obj.ContextMenu = AppSpaceElementsFactory.createContextMenu(parent, ...
                    obj.TableHandle);

                obj.MenuItems = ...
                    AppSpaceElementsFactory.createMenu(obj.ContextMenu, obj.Constants.ContextMenuLabels, {@obj.menuSelected});
            end
        end

        function clearTableContextMenu(obj, ~, ~)
            % Cleans up the context menu options.

            if obj.ProductionMode
                obj.MenuItems = [];
                obj.ContextMenu = [];
                obj.TableHandle.ContextMenu = [];
            end
        end
    end

    %% Private Helper Functions
    methods (Access = private)
        function setupListeners(obj)
            obj.CellSelectionListener = listener(obj.View, "TableRowSelected", ...
                @(src, evt)obj.tableIndexSelected(src, evt));
        end

        function menuSelected(obj, ~, ~)
            obj.ExportMenuItemPressed = true;
        end
    end

    %% Getters and setters
    methods
        function value = get.TableHandle(obj)
            value = obj.View.Table;
        end

        function value = get.View(obj)
            value = obj.ViewConfiguration.View;
        end
    end
end
