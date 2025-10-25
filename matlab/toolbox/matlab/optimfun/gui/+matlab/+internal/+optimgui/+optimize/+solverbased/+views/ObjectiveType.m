classdef ObjectiveType < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The ObjectiveType view class manages the widgets for specifying the problem
    % objective type in the solver-based Optimize LET
    
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
    end
    
    methods (Access = public)
        
        function obj = ObjectiveType(parentContainer)
        
        % Set view properties
        tag = 'ObjectiveType';
        row = 1;
        
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
        trueInd= num2cell(strcmp({obj.StateButtons.Tag}, obj.Model.ObjectiveType));
        [obj.StateButtons.Value] = trueInd{:};
        
        % Update Examples interpreter and text
        if any([obj.StateButtons.Value])
            obj.Examples.Interpreter = 'latex';
        else
            obj.Examples.Interpreter = 'none';
        end
        obj.Examples.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', [obj.Model.ObjectiveType, 'Examples']);
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Label
        obj.Label = uilabel(obj.ParentContainer);
        obj.Label.Layout.Row = obj.Row;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'ObjectiveType');
        
        % Name of objective buttons to make
        [tagList, ia] = setdiff(matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ObjectiveKeys, 'Unsure', 'stable');
        iconNameList = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ObjectiveKeyIconNames(ia);
        
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
        obj.ButtonsGrid.ColumnWidth = repmat({'fit'}, 1, numel(tagList));
        obj.ButtonsGrid.RowHeight = {68};
        
        % WidthButtons and StateButtons
        for count = 1:numel(tagList)
            obj.WidthButtons(count) = uibutton(obj.ButtonsGrid);
            obj.WidthButtons(count).Layout.Row = 1;
            obj.WidthButtons(count).Layout.Column = count;
            obj.WidthButtons(count).Visible = 'off';
            obj.WidthButtons(count).Text = 'MMMMMMMMMM'; % ~110 pixels
            
            obj.StateButtons(count) = uibutton(obj.ButtonsGrid, 'state');
            obj.StateButtons(count).Layout.Row = 1;
            obj.StateButtons(count).Layout.Column = count;
            matlab.ui.control.internal.specifyIconID(obj.StateButtons(count), iconNameList{count}, 50, 40);
            obj.StateButtons(count).VerticalAlignment = 'bottom';
            obj.StateButtons(count).IconAlignment = 'top';
            obj.StateButtons(count).Text = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', [tagList{count}, 'Button']);
            obj.StateButtons(count).Tag = tagList{count};
            obj.StateButtons(count).ValueChangedFcn = @obj.valueChanged;
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
        obj.Examples.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', ['Unsure', 'Examples']);
        end
        
        function valueChanged(obj, src, ~)
        
        % Callback for clicking any StateButton
        
        % If a button was selected, make this new selection the only selected
        % button. Also, update the Model.ObjectiveType property and the Examples interpreter.
        % Else, set the Model.ObjectiveType property to 'Unsure' and update the Examples interpreter
        if src.Value
            
            trueInd = num2cell(strcmp({obj.StateButtons.Tag}, src.Tag));
            [obj.StateButtons.Value] = trueInd{:};
            
            obj.Model.ObjectiveType = src.Tag;
            obj.Examples.Interpreter = 'latex';
        elseif ~src.Value
            
            obj.Model.ObjectiveType = 'Unsure';
            obj.Examples.Interpreter = 'none';
        end
        
        % Set the Examples text based on the Model.ObjectiveType property
        obj.Examples.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', [obj.Model.ObjectiveType, 'Examples']);
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
    end
end
