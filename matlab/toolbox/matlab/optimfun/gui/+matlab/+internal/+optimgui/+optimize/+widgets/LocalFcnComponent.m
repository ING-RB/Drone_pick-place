classdef LocalFcnComponent < matlab.internal.optimgui.optimize.widgets.AbstractFcnComponent
    % The LocalFcnComponent class wraps a DropDown component to select a local
    % function in the current active editor
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = public)

        % Value is the dropdown selection
        Value = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue; % (1, :) char
    end

    properties (Hidden, Access = public, Transient, NonCopyable)

        % Additional components to refresh function arguments
        RefreshIconGrid (1, 1) matlab.ui.container.GridLayout
        RefreshIcon (1, 1) matlab.ui.control.Image
    end

    methods (Access = protected)

        function setup(this)

            % Call superclass method
            setup@matlab.internal.optimgui.optimize.widgets.AbstractFcnComponent(this);

            % Extend grid
            this.Grid.ColumnWidth = {'fit', 0};

            % Input
            this.Input = uidropdown(this.Grid);
            this.Input.Layout.Row = 1;
            this.Input.Layout.Column = 1;
            this.Input.Items = {matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'LocalFcnDefault')};
            this.Input.ItemsData = {matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue};
            this.Input.ValueChangedFcn = @this.inputChanged;
            this.Input.DropDownOpeningFcn = @this.populateDropDown;

            % RefreshIconGrid
            this.RefreshIconGrid = uigridlayout(this.Grid);
            this.RefreshIconGrid.Layout.Row = 1;
            this.RefreshIconGrid.Layout.Column = 2;
            this.RefreshIconGrid.Padding = [0, 0, 0, 0];
            this.RefreshIconGrid.RowHeight = {matlab.internal.optimgui.optimize.OptimizeConstants.RowHeight};
            this.RefreshIconGrid.ColumnWidth = {matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth};

            % RefreshIcon
            this.RefreshIcon = uiimage(this.RefreshIconGrid);
            this.RefreshIcon.Layout.Row = 1;
            this.RefreshIcon.Layout.Column = 1;
            matlab.ui.control.internal.specifyIconID(this.RefreshIcon, "refresh", 16, 16);
            this.RefreshIcon.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'RefreshFcnTooltip');
            this.RefreshIcon.ImageClickedFcn = @this.refresh;
        end

        function updateValue(this)

            % If value is not already in the DropDown list, append value
            % to Items and ItemsData properties
            if ~any(strcmp(this.Input.ItemsData, this.Value))
                this.Input.Items = [this.Input.Items, this.Value];
                this.Input.ItemsData = [this.Input.ItemsData, this.Value];
            end

            % Set input from the component Value
            this.Input.Value = this.Value;

            % Make RefreshIcon visible only if a function is selected
            if strcmp(this.Value, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue)
                this.Grid.ColumnWidth{2} = 0;
            else
                this.Grid.ColumnWidth{2} = 'fit';
            end
        end

        function inputChanged(this, ~, ~)

            % Store previous value to include in ValueChanged event data
            previousValue = this.Value;

            % Set the component value
            this.Value = this.Input.Value;

            % Notify listeners the value changed, along with fcn name and previous value
            data = struct('FcnName', this.Value, 'PreviousValue', previousValue);
            eventData = matlab.internal.optimgui.optimize.OptimizeEventData(data);
            this.notify('ValueChanged', eventData);
        end
    end

    methods (Hidden, Access = public)

        function populateDropDown(this, ~, ~)
            % DropDownOpeningFcn callback
            % Populate dropdown with local functions in the current script

            % Reference
            oldValue = this.Input.Value;
            oldIndex = find(strcmp(this.Input.ItemsData, oldValue));
            placeholderValue = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;

            % Get active script text
            d = matlab.desktop.editor.getActive;
            if ~isempty(d)

                % Return the names of the local functions in the active script.
                % If the script code contains a parse error, it seems mtree returns an empty cell
                treeFile = mtree(d.Text);
                treeFcns = mtfind(treeFile, 'Kind', 'FUNCTION');
                treeFcnNames = Fname(treeFcns);
                cellFcnNames = treeFcnNames.List.strings;

                % Empty the list if duplicates exist
                if numel(unique(cellFcnNames)) < numel(cellFcnNames)
                    cellFcnNames = cell(0);
                end

                % Update dropdown selections
                this.Input.Items = [{matlab.internal.optimgui.optimize.utils.getMessage(...
                    'Labels', 'LocalFcnDefault')}, cellFcnNames];
                this.Input.ItemsData = [{placeholderValue}, cellFcnNames];
            else

                % If the script text is empty, update dropdown selection
                % to default value
                this.Input.Items = {matlab.internal.optimgui.optimize.utils.getMessage(...
                    'Labels', 'LocalFcnDefault')};
                this.Input.ItemsData = {placeholderValue};
            end

            % Find index of the dropdown selection when the dropdown was opened
            newIndex = find(strcmp(this.Input.ItemsData, oldValue));

            if isempty(newIndex)
                % the old value no longer exists in the item list. revert to
                % placeholder value and notify listeners
                previousValue = this.Value;
                this.Value = placeholderValue;
                data = struct('FcnName', this.Value, 'PreviousValue', previousValue);
                eventData = matlab.internal.optimgui.optimize.OptimizeEventData(data);
                this.notify('ValueChanged', eventData);
            elseif newIndex ~= oldIndex
                % A local function has been created since the last time
                % the dropdown was populated, and it came before the
                % previous selection. to maintain the current selection, we
                % need to set the value again explicitly
                this.Value = oldValue;
            end
        end

        function refresh(this, ~, ~)

            % populateDropDown() ensures the selected fcn is still valid
            this.populateDropDown();

            % If the selected fcn was NOT reset after calling populateDropDown(),
            % notify listeners of the selected fcn name to re-parse
            if ~strcmp(this.Value, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue)
                data = struct('FcnName', this.Value, 'PreviousValue', this.Value);
                eventData = matlab.internal.optimgui.optimize.OptimizeEventData(data);
                this.notify('ValueChanged', eventData);
            end
        end
    end

    methods (Static, Access = public)

        function createTemplate(fcnName, fcnText)

            % Append fcnText to the bottom of the script and go to this new fcn
            d = matlab.desktop.editor.getActive;
            fcnText = [newline, fcnText, newline]; % Pad fcnText with newline chars
            d.appendText(fcnText);
            d.goToFunction(fcnName);
        end
    end
end
