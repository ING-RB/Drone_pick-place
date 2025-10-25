classdef ObjectiveFunction < matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp
    % The ObjectiveFunction view class manages the widgets for the objective function
    % section of the solver-based Optimize LET
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        
        % For alignment purposes, place the label in its own grid
        LabelGrid (1, 1) matlab.ui.container.GridLayout
        
        % Objective fcn section label
        Label (1, 1) matlab.ui.control.Label
        
        % Grid for components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % Input widget for the objective fcn
        FcnInput matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionView
        
        % For alignment purposes, place CshImage in its own grid
        CshGrid (1, 1) matlab.ui.container.GridLayout

        % Listen for changes to FcnInput
        lhFcnInputChanged event.listener
    end
    
    methods (Access = public)
        
        function obj = ObjectiveFunction(parentContainer)
        
        % Set view properties
        tag = 'ObjectiveFunction';
        row = 1;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp(...
            parentContainer, tag, row);

        % Listen for changes to FcnArgumentsView
        wrefObj = matlab.lang.WeakReference(obj);
        obj.lhFcnInputChanged = listener(...
            obj.FcnInput, 'ValueChangedEvent', @(s,e)valueChanged(wrefObj.Handle,s,e));
        end
        
        function updateView(obj, model)
        
        % This method is called in the constructor, by the Optimize class everytime the SolverModel
        % changes, and on undo/redo. It sets the view to the current state of the Model
        
        % Update Model reference
        obj.Model = model;
        
        % If the current SolverModel does NOT have an ObjectiveFcn property,
        % hide the ObjectiveFcn section and exit the method
        if ~isprop(obj.Model, 'ObjectiveFcn')
            
            % Hide section by setting parent container RowHeight and Grid widths to 0
            obj.ParentContainer.RowHeight{obj.Row} = 0;
            obj.Grid.ColumnWidth = {0, 0};
            
            % Empty Label so column width is only influenced by visible labels
            obj.Label.Text = '';
            return
        end
        
        % Set Label and Label.Tooltip
        obj.Label.Text = obj.Model.ObjectiveFcn.DisplayLabel;
        obj.Label.Tooltip = obj.Model.ObjectiveFcn.DisplayLabelTooltip;

		% Update FcnInput view
        obj.FcnInput.updateView(obj.Model.ObjectiveFcn);
        
        % Show section by setting Parent height and Grid widths to 'fit'
        obj.ParentContainer.RowHeight{obj.Row} = 'fit';
        obj.Grid.ColumnWidth = {'fit', 'fit'};
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % LabelGrid
        obj.LabelGrid = uigridlayout(obj.ParentContainer);
        obj.LabelGrid.Layout.Row = obj.Row;
        obj.LabelGrid.Layout.Column = 1;
        obj.LabelGrid.ColumnWidth = {'fit'};
        obj.LabelGrid.RowHeight = {obj.RowHeight};
        obj.LabelGrid.RowSpacing = 0;
        obj.LabelGrid.Padding = [0, 0, 0, 0];
        
        % Label
        obj.Label = uilabel(obj.LabelGrid);
        obj.Label.Layout.Row = 1;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = '';
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.ColumnWidth = {'fit', 'fit'};
        obj.Grid.RowHeight = {'fit'};
        obj.Grid.Padding = [0, 0, 0, 0];
        
        % FcnInput
        obj.FcnInput = matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionView(...
            obj.Grid, 'ObjectiveFcn');
        
        % CshGrid
        obj.CshGrid = uigridlayout(obj.Grid);
        obj.CshGrid.ColumnWidth = {matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth};
        obj.CshGrid.RowHeight = {obj.RowHeight};
        obj.CshGrid.RowSpacing = 0;
        obj.CshGrid.Padding = [0, 0, 0, 0];
        obj.CshGrid.Layout.Row = 1;
        obj.CshGrid.Layout.Column = 2;
        
        % CshImage
        parent = obj.CshGrid;
        row = 1;
        col = 1;
        tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'fcnLink');
        tag = 'ObjectiveFcnHelpIcon';
        obj.createHelpIcon(parent, row, col, tooltip, tag);
        end
        
        function cshImageClicked(obj, ~, ~)
        
        % Callback when the user clicks the CshImage
        
        % Include doc link with eventData
        docLink = obj.Model.ObjectiveFcn.WidgetProperties.DocLinkID;
        eventData = matlab.internal.optimgui.optimize.OptimizeEventData(docLink);
        notify(obj, 'CshImageClickedEvent', eventData);
        end
    end
end
