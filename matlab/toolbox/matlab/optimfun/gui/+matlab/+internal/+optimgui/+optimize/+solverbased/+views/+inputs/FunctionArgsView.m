classdef FunctionArgsView < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % Manage the front-end of function arguments for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access = public)

        % Accordion, accordion panel, and grid to place fcn argument objects into
        Accordion (1, 1) matlab.ui.container.internal.Accordion
        AccordionPanel (1, 1) matlab.ui.container.internal.AccordionPanel
        Grid (1, 1) matlab.ui.container.GridLayout

        % Label and DropDown for selecting the free (optimization) variable
        FreeVariableLabel (1, 1) matlab.ui.control.Label
        FreeVariableDropDown (1, 1) matlab.ui.control.DropDown

        % Labels and WorkspaceDropDowns to input the fixed values
        FixedValuesLabel (1, :) matlab.ui.control.Label
        FixedValuesDropDown (1, :) matlab.ui.control.internal.model.WorkspaceDropDown
    end

    methods (Access = public)

        function this = FunctionArgsView(parentContainer, tag)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
                parentContainer, tag);
        end

        function updateView(this, model)

            % Update Model reference
            this.Model = model;

            % Unpack some model values
            variableList = this.Model.Value.VariableList;
            freeVariable = this.Model.Value.FreeVariable;
            fixedValues = this.Model.Value.FixedValues;

            % If there are no fcn args OR number of inputs are at/below threshold
            % then reset/hide and exit method
            if isempty(variableList) || ...
                    numel(variableList) <= this.Model.WidgetProperties.NumberOfArgsThresh || ...
                    ~isempty(this.Model.WidgetProperties.Message)
                this.setParentGridRowAndHeight(0);
                return
            end

            % Reset fcn arg components
            this.FreeVariableDropDown.Items = cell(0);
            delete([this.FixedValuesLabel(:), this.FixedValuesDropDown(:)]);
            this.FixedValuesLabel(:) = [];
            this.FixedValuesDropDown(:) = [];
            this.ParentContainer.RowHeight = {0};

            % Set FreeVariableDropDown
            this.FreeVariableDropDown.Items = variableList;
            this.FreeVariableDropDown.Value = freeVariable;

            % Create fixed variable labels and dropdowns
            inputCount = numel(this.Model.Value.VariableList) - 1;
            for ct = 2:inputCount + 1
                this.createLabel(ct); % FixedValuesLabel
                this.createDropDown(ct); % FixedValuesDropDown
            end

            % Set FixedValuesLabel text and tag
            this.setFixedValuesLabel(variableList, freeVariable);

            % Set the FixedValuesDropDown
            for ct = 1:numel(fixedValues)
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FixedValuesDropDown(ct), fixedValues{ct});
            end

            % Set all Grid rows to a height of 'fit'.
            % Numbers of rows is equal to the total number of variables
            this.Grid.RowHeight = repmat({'fit'}, 1, numel(variableList));

            % Ensure fcn input components are visible
            drawnow nocallbacks
            this.setParentGridRowAndHeight('fit');
        end

        function setParentGridRowAndHeight(this, val)

            % Sets the visibilty of the view by adjusting the RowHeight
            % and ColumnWidth of the parent container grid.
            % Input arg "val" should be 0 or 'fit'
            this.ParentContainer.RowHeight = {val};
            this.ParentContainer.ColumnWidth = {val};
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Accordion
            this.Accordion = matlab.ui.container.internal.Accordion('Parent', this.ParentContainer);
            this.Accordion.Layout.Row = 1;
            this.Accordion.Layout.Column = 1;

            % AccordionPanel
            this.AccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', this.Accordion);
            this.AccordionPanel.Title = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'FunctionInputs');
            this.AccordionPanel.FontWeight = 'normal';

            % Grid
            this.Grid = uigridlayout(this.AccordionPanel);
            this.Grid.RowHeight = {'fit', 'fit'};
            this.Grid.ColumnWidth = {'fit', 'fit'};
            this.Grid.Padding = [0, 0, 0, 0];

            % FreeVariableLabel
            this.FreeVariableLabel = uilabel(this.Grid);
            this.FreeVariableLabel.Layout.Row = 1;
            this.FreeVariableLabel.Layout.Column = 1;
            this.FreeVariableLabel.Text = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', 'FreeVariable');

            % FreeVariableDropDown
            this.FreeVariableDropDown = uidropdown(this.Grid);
            this.FreeVariableDropDown.Layout.Row = 1;
            this.FreeVariableDropDown.Layout.Column = 2;
            this.FreeVariableDropDown.Items = cell(0);
            this.FreeVariableDropDown.ValueChangedFcn = @this.freeVariableChanged;
            this.FreeVariableDropDown.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Tooltips', 'FreeVariable');
            this.FreeVariableDropDown.Tag = [this.Tag, 'OptimInput'];
        end

        function freeVariableChanged(this, src, event)

            % Previous fixed args
            prevFixedArgs = setdiff(src.Items, event.PreviousValue, 'stable');

            % Update the FixedValuesLabel array to show fixed fcn arguments
            newFixedArgs = this.setFixedValuesLabel(src.Items, src.Value);

            % Also move FixedValuesDropDown.Value so that still viable label-value
            % pairs remain consistent
            values = {this.FixedValuesDropDown.Value};
            for ct = 1:numel(this.FixedValuesDropDown)
                newInd = find(strcmp(prevFixedArgs, newFixedArgs{ct}), 1);
                if isempty(newInd)
                    newInd = find(strcmp(prevFixedArgs, src.Value), 1);
                end
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FixedValuesDropDown(ct), values{newInd});
            end

            % Update model
            this.Model.Value.FreeVariable = char(src.Value);
            this.Model.Value.FixedValues = {this.FixedValuesDropDown.Value};

            % Call valueChanged() method
            this.valueChanged();
        end

        function fixedVariableChanged(this, ~, ~)

            % Update model
            this.Model.Value.FixedValues = {this.FixedValuesDropDown.Value};

            % Call valueChanged() method
            this.valueChanged();
        end

        function createLabel(this, row)

            % Make a new FixedValuesLabel component
            h = uilabel(this.Grid);
            h.Layout.Row = row;
            h.Layout.Column = 1;
            this.FixedValuesLabel = [this.FixedValuesLabel, h];
        end

        function createDropDown(this, row)

            % Make a new FixedValueDropDown component
            h = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.Grid);
            h.Layout.Row = row;
            h.Layout.Column = 2;
            h.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'FixedValue');
            h.ValueChangedFcn = @this.fixedVariableChanged;
            this.FixedValuesDropDown = [this.FixedValuesDropDown, h];
        end

        function fixedInputs = setFixedValuesLabel(this, variableList, freeVariable)

            % Set FixedValuesLabel text and tag
            fixedInputs = reshape(setdiff(variableList, freeVariable, 'stable'), [], 1);
            prefaceLabel = repmat({matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', 'FixedInputs')}, size(fixedInputs));
            labels = join([prefaceLabel, fixedInputs]);
            [this.FixedValuesLabel.Text] = labels{:};
            [this.FixedValuesDropDown.Tag] = deal([this.Tag, 'FixedInput']);
        end
    end
end
