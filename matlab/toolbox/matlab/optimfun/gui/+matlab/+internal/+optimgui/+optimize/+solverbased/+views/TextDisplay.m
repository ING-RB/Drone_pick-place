classdef TextDisplay < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The TextDisplay view class manages the widgets for the text display
    % section of the solver-based Optimize LET
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Hidden, GetAccess = public, SetAccess = private)
        
        % Label for text display dropdown
        Label (1, 1) matlab.ui.control.Label
        
        % Grid for text display dropdown, required to 'fit' to dropdown items
        % Do not want width influenced by plot fcn components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % DropDown for setting text display value
        DropDown (1, 1) matlab.ui.control.DropDown
    end
    
    methods (Access = public)
        
        function obj = TextDisplay(parentContainer)
        
        % Set view properties
        tag = 'TextDisplay';
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
        
        % Set text display dropdown items and value
        [obj.DropDown.ItemsData, obj.DropDown.Items] = ...
            obj.Model.getTextDisplayNames;
        obj.DropDown.Value = obj.Model.getOptionValue('Display');
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Label
        obj.Label = uilabel(obj.ParentContainer);
        obj.Label.Layout.Row = obj.Row;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'TextDisplay');
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.Padding = [0, 0, 0, 0];
        obj.Grid.ColumnWidth = {'fit'};
        obj.Grid.RowHeight = {'fit'};
        
        % DropDown
        obj.DropDown = uidropdown(obj.Grid);
        obj.DropDown.Layout.Row = 1;
        obj.DropDown.Layout.Column = 1;
        obj.DropDown.ValueChangedFcn = @obj.valueChanged;
        obj.DropDown.Tag = 'Display';
        end
        
        function valueChanged(obj, src, ~)
        
        % Callback for changing the DropDown
        
        % Set model's Display option value
        obj.Model.setOptionValue(src.Tag, src.Value);
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
    end
end
