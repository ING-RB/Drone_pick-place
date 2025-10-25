classdef SelectSolver < matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp
    % The SelectSolver view class manages the widgets for specifying the
    % solver in the solver-based Optimize LET
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Hidden, GetAccess = public, SetAccess = private)
        
        % Row label
        Label (1, 1) matlab.ui.control.Label
        
        % Grid for components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % DropDown for selecting the solver
        DropDown (1, 1) matlab.ui.control.DropDown
    end
    
    methods (Access = public)
        
        function obj = SelectSolver(parentContainer)
        
        % Set view properties
        tag = 'SelectSolver';
        row = 3;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp(...
            parentContainer, tag, row);
        end
        
        function updateView(obj, model)
        
        % This method is called in the constructor and by the Optimize class on undo/redo.
        % Sets view to the current state of the Model
        
        % Update Model reference
        obj.Model = model;
        
        % Update DropDown
        obj.DropDown.ItemsData = obj.Model.SolverList;
        obj.DropDown.Items = obj.Model.SolverListMessage;
        obj.DropDown.Value = obj.Model.SolverName;
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Label
        obj.Label = uilabel(obj.ParentContainer);
        obj.Label.Layout.Row = obj.Row;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'Solver');
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.Padding = [0, 0, 0, 0];
        obj.Grid.ColumnWidth = {470, matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth};
        obj.Grid.RowHeight = {obj.RowHeight};
        
        % DropDown
        obj.DropDown = uidropdown(obj.Grid);
        obj.DropDown.Layout.Row = 1;
        obj.DropDown.Layout.Column = 1;
        obj.DropDown.ValueChangedFcn = @obj.valueChanged;
        obj.DropDown.Tag = 'Solver';
        obj.DropDown.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'SolverDropDown');
        
        % CshImage
        parent = obj.Grid;
        row = 1;
        col = 2;
        tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'solverLink');
        tag = 'SelectSolverHelpIcon';
        obj.createHelpIcon(parent, row, col, tooltip, tag);
        end
        
        function valueChanged(obj, src, ~)
        
        % Callback when selecting a new solver from the dropdown
        
        % Set model SolverName property from input
        obj.Model.SolverName = src.Value;
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
        
        function cshImageClicked(obj, ~, ~)
        
        % Callback when the user clicks the CshImage
        
        % If the user has a license for the solver, notify listeners and include
        % the solver's doc link with eventData.
        % Else, the dropdown contains a 'license needed' message so link to product
        % add-on page
        if obj.Model.hasLicense
            eventData = matlab.internal.optimgui.optimize.OptimizeEventData(obj.Model.SolverName);
            notify(obj, 'CshImageClickedEvent', eventData);
        else
            matlab.internal.addons.launchers.showExplorer('DUMMY-ID', 'identifier', ...
                matlab.internal.optimgui.optimize.utils.getMessage('DocLinks', obj.Model.SolverName));
        end
        end
    end
end
