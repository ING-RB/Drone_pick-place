classdef ConstraintType < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The ConstraintType view class manages the widgets for specifying the
    % problem constraint type in the solver-based Optimize LET
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Hidden, GetAccess = public, SetAccess = private)
        
        % Row label
        Label (1, 1) matlab.ui.control.Label
        
        % Grid for components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % Place buttons in their own Grid
        ButtonsGrid (1, 1) matlab.ui.container.GridLayout
        
        % Buttons for setting a minimum width for the grid
        WidthButtons (1, :) matlab.ui.control.Button
        
        % Buttons for specifying objective type
        StateButtons (1, :) matlab.ui.control.StateButton

        % Place example label in it's own grid
        ExamplesGrid (1, 1) matlab.ui.container.GridLayout
        
        % Examples label for the specified objective type
        Examples (1, 1) matlab.ui.control.Label
        
        % Constraint buttons per row
        PerRow (1, 1) double = 4;
    end
    
    events
        
        % Notify listeners when constraint inputs need to be removed from view
        RemoveConstraintsEvent
        
        % Notify listeners to update Constraints view grid visibility
        UpdateConstraintsGridEvent
    end
    
    methods (Access = public)
        
        function obj = ConstraintType(parentContainer)
        
        % Set view properties
        tag = 'ConstraintType';
        row = 2;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
            parentContainer, tag, row);
        end
        
        function updateView(obj, model)
        
        % This method is called in the constructor and by the Optimize class on undo/redo.
        % Sets view to the current state of the Model
        
        % Update Model reference
        obj.Model = model;
        
        % Update selected buttons
        trueInd = num2cell(ismember({obj.StateButtons.Tag}, obj.Model.ConstraintType));
        [obj.StateButtons.Value] = trueInd{:};
        
        % Set Examples
        [obj.Examples.Text, obj.Examples.Interpreter] = obj.getExamples();
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Label
        obj.Label = uilabel(obj.ParentContainer);
        obj.Label.Layout.Row = obj.Row;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'ConstraintType');
        
        % Name of constraint buttons to make. Set 4 per row
        [tagList, ia] = setdiff(matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ConstraintKeys, 'Unsure', 'stable');
        iconNameList = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ConstraintKeyIconNames(ia);
        obj.PerRow = 4;
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.Padding = [0, 0, 0, 0];
        obj.Grid.ColumnWidth = {'fit'};
        obj.Grid.RowHeight = {'fit', 'fit'};

        % ButtonsGrid
        obj.ButtonsGrid = uigridlayout(obj.Grid);
        obj.ButtonsGrid.Layout.Row = 1;
        obj.ButtonsGrid.Layout.Column = 1;
        obj.ButtonsGrid.Padding = [0, 0, 0, 0];
        obj.ButtonsGrid.ColumnWidth = repmat({'fit'}, 1, obj.PerRow);
        obj.ButtonsGrid.RowHeight = {35, 35};
        
        % WidthButtons and StateButtons, set 4 per row
        for count = 1:numel(tagList)
            obj.WidthButtons(count) = uibutton(obj.ButtonsGrid);
            obj.WidthButtons(count).Layout.Row = ceil(count / obj.PerRow);
            obj.WidthButtons(count).Layout.Column = count - ((obj.WidthButtons(count).Layout.Row - 1) * obj.PerRow);
            obj.WidthButtons(count).Visible = 'off';
            obj.WidthButtons(count).Text = 'MMMMMMMMMMMMM'; % ~140 pixels
            
            obj.StateButtons(count) = uibutton(obj.ButtonsGrid, 'state');
            obj.StateButtons(count).Layout.Row = ceil(count / obj.PerRow);
            obj.StateButtons(count).Layout.Column = count - ((obj.StateButtons(count).Layout.Row - 1) * obj.PerRow);
            matlab.ui.control.internal.specifyIconID(obj.StateButtons(count), iconNameList{count}, 24, 24);
            obj.StateButtons(count).HorizontalAlignment = 'left';
            obj.StateButtons(count).IconAlignment = 'left';
            obj.StateButtons(count).Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', [tagList{count}, 'Button']);
            obj.StateButtons(count).Tag = tagList{count};
            obj.StateButtons(count).ValueChangedFcn = @obj.valueChanged;
            obj.StateButtons(count).Interruptible = 'off';
            obj.StateButtons(count).BusyAction = 'cancel';
        end
        
        % ExamplesGrid
        obj.ExamplesGrid = uigridlayout(obj.Grid);
        obj.ExamplesGrid.Layout.Row = 2;
        obj.ExamplesGrid.Layout.Column = 1;
        obj.ExamplesGrid.Padding = [0, 0, 0, 0];
        obj.ExamplesGrid.ColumnWidth = {'fit'};
        obj.ExamplesGrid.RowHeight = {'fit'};
        
        % Examples
        obj.Examples = uilabel(obj.ExamplesGrid, 'Interpreter', 'none');
        obj.Examples.Layout.Row = 1;
        obj.Examples.Layout.Column = 1;
        obj.Examples.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'UnsureExample');
        end
        
        function valueChanged(obj, src, ~)
        
        % Callback for clicking any StateButton
        
        % If 'None' was selected, set 'None' as the only selected button
        % Else, make sure 'None' is not selected
        if strcmp(src.Tag, 'None') && src.Value
            trueInd= num2cell(strcmp({obj.StateButtons.Tag}, src.Tag));
            [obj.StateButtons.Value] = trueInd{:};
        else
            makeFalseInd = strcmp({obj.StateButtons.Tag}, 'None');
            obj.StateButtons(makeFalseInd).Value = false;
        end
        
        % Cellstr of currently selected constraints
        selectedConstraints = {obj.StateButtons([obj.StateButtons.Value]).Tag};
        
        % If this SolverModel has Constraints AND either 'None' was selected OR a constraint was removed,
        % notify listeners to reset the removed constraints.
        % Updating ConstraintType may change the solver, so we need to remove the constraints
        % before this can happen. The SolverModel is told to reset the constraints to
        % their default value, but if the solver changes, those constraint inputs may not
        % exist for the new solver.
        if ~isempty(obj.Model.SolverModel.Constraints) && (strcmp(src.Tag, 'None') || ~src.Value)
            
            removedConstraints = setdiff(obj.Model.SolverModel.SelectedConstraintNames, selectedConstraints);
            eventData = matlab.internal.optimgui.optimize.OptimizeEventData(removedConstraints);
            notify(obj, 'RemoveConstraintsEvent', eventData);
        end
        
        % Set model ConstraintType property from input, this may change the solver
        solverName = obj.Model.SolverName;
        if isempty(selectedConstraints)
            obj.Model.ConstraintType = {'Unsure'};
        else
            obj.Model.ConstraintType = selectedConstraints;
        end
        
        % Set Examples
        [obj.Examples.Text, obj.Examples.Interpreter] = obj.getExamples();
        
        % If the user has a license for the specified problem type AND the solver was not changed
        % AND the solver has constraints, notify listeners to update Constraints view grid visibility.
        % If the solver changed, the Optimize class sets the SolverModel and calls
        % updateView, which already does this. Don't re-do it here
        if obj.Model.hasLicense && strcmp(solverName, obj.Model.SolverName) && ...
                ~isempty(obj.Model.SolverModel.Constraints)
            eventData = matlab.internal.optimgui.optimize.OptimizeEventData(src.Tag);
            notify(obj, 'UpdateConstraintsGridEvent', eventData)
        end
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
        
        function [examples, interpreter] = getExamples(obj)
        
        % Called by valueChanged method to set the Examples property
        
        % If the problem is unconstrained or no constraints are specified,
        % return the example, latex is not required for the label message.
        % Else, loop through the selected constraints, append their examples
        % and set the interpreter
        if any(ismember(obj.Model.ConstraintType, {'Unsure', 'None'}))
            examples = matlab.internal.optimgui.optimize.utils.getMessage('Labels', [obj.Model.ConstraintType{:}, 'Example']);
            interpreter = 'none';
        else
            allExamples = cell(size(obj.Model.ConstraintType));
            for count = 1:numel(allExamples)
                allExamples{count} = matlab.internal.optimgui.optimize.utils.getMessage('Labels', ...
                    [obj.Model.ConstraintType{count}, 'Example']);
            end
            examples = ['Examples: $', strjoin(allExamples, '$, $'), '$'];
            interpreter = 'latex';
        end
        end
    end
end
