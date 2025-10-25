classdef Solver < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The Solver view class manages the widgets for the miscellaneous solver
    % inputs section (InitialPoint, NumberOfVariables, etc.) if the
    % solver-based Optimize LET 
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        
        % Label for solver inputs
        Labels (1, 3)  matlab.ui.control.Label
        
        % Grid for components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % Input widget for solver inputs
        WorkspaceDropDowns (1, 3) matlab.ui.control.internal.model.WorkspaceDropDown
    end
    
    methods (Access = public)
        
        function obj = Solver(parentContainer)
        
        % Set view properties
        tag = 'SolverInputs';
        row = 2;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
            parentContainer, tag, row);
        end
        
        function updateView(obj, model)
        
        % This method is called in the constructor, by the Optimize class everytime the SolverModel
        % changes, and on undo/redo. It sets the view to the current state of the Model
        
        % Update Model reference
        obj.Model = model;

        % Number of solver inputs
        numInputs = numel(obj.Model.SolverMiscInputsAll);
        
        % If this solver has no inputs, hide the section and exit the method
        if numInputs == 0
            
            % Hide section by setting RowHeight and ColumnWidth to 0
            obj.ParentContainer.RowHeight{obj.Row} = 0;
            obj.Grid.ColumnWidth = repmat({0}, 1, 5);
            return
        end
        
        % Loop through each solver input to view
        for count = 1:numInputs
            
            % Input name
            inputName = obj.Model.SolverMiscInputsAll{count};
            
            % Set Labels
            obj.Labels(count).Text = obj.Model.(inputName).DisplayLabel;
            obj.Labels(count).Tooltip = obj.Model.(inputName).DisplayLabelTooltip;
            
            % Set WorkspaceDropDowns Tag
            obj.WorkspaceDropDowns(count).Tag = obj.Model.(inputName).StatePropertyName;
            
            % Set widget properties, will be different across solvers and inputs
            for iterWidgetProperty = obj.Model.(inputName).WidgetPropertyNames
                thisProp = iterWidgetProperty{:};
                if strcmp(thisProp, 'Message') % Not applicable to WorkspaceDropDowns
                    continue
                end
                obj.WorkspaceDropDowns(count).(thisProp) = ...
                    obj.Model.(inputName).WidgetProperties.(thisProp);
            end
            
            % Set widget value from model
            matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(obj.WorkspaceDropDowns(count), ...
                obj.Model.(inputName).Value);
        end
        
        % Hide unneeded Labels and DropDowns
        columnWidths = {'fit', 0, 0, 0, 0};
        if numInputs > 1
            columnWidths(2:3) = {'fit'};
            if numInputs > 2
                columnWidths(4:5) = {'fit'};
            end
        end
        obj.Grid.ColumnWidth = columnWidths;
        
        % Show section by setting RowHeight to 'fit'
        obj.ParentContainer.RowHeight{obj.Row} = 'fit';
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.ColumnWidth = repmat({'fit'}, 1, 5);
        obj.Grid.RowHeight = {'fit'};
        obj.Grid.Padding = [0, 0, 0, 0];
        
        % Labels(1) in obj.ParentContainer, Labels(2:3) in obj.Grid
        obj.Labels = [uilabel(obj.ParentContainer), uilabel(obj.Grid), uilabel(obj.Grid)];
        obj.Labels(1).Layout.Row = obj.Row;
        obj.Labels(2).Layout.Row = 1;
        obj.Labels(3).Layout.Row = 1;
        obj.Labels(1).Layout.Column = 1;
        obj.Labels(2).Layout.Column = 2;
        obj.Labels(3).Layout.Column = 4;
        
        % WorkspaceDropDowns
        obj.WorkspaceDropDowns = [matlab.ui.control.internal.model.WorkspaceDropDown('Parent', obj.Grid), ...
            matlab.ui.control.internal.model.WorkspaceDropDown('Parent', obj.Grid), ...
            matlab.ui.control.internal.model.WorkspaceDropDown('Parent', obj.Grid)];
        [obj.WorkspaceDropDowns.ValueChangedFcn] = deal(@obj.valueChanged);
        obj.WorkspaceDropDowns(1).Layout.Row = 1;
        obj.WorkspaceDropDowns(2).Layout.Row = 1;
        obj.WorkspaceDropDowns(3).Layout.Row = 1;
        obj.WorkspaceDropDowns(1).Layout.Column = 1;
        obj.WorkspaceDropDowns(2).Layout.Column = 3;
        obj.WorkspaceDropDowns(3).Layout.Column = 5;
        end
        
        function valueChanged(obj, src, ~)
        
        % Callback for changing any WorkspaceDropDown
        
        % Set model's Input.Value property from widget
        obj.Model.(src.Tag).Value = src.Value;
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
    end
end
