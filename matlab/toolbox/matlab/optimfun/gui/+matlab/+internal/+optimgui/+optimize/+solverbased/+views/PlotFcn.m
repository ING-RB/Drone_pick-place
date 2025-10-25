classdef PlotFcn < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The PlotFcn view class manages the widgets for the text display
    % section of the solver-based Optimize LET
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Hidden, GetAccess = public, SetAccess = private)
        
        % Label for text display dropdown
        Label (1, 1) matlab.ui.control.Label
        
        % Grid for text display dropdown, required to 'fit' to dropdown items
        % Do not want width influenced by plot fcn components
        Grid (1, 1) matlab.ui.container.GridLayout
        
        % CheckBoxes for selecting plot fcn values
        Inputs (1, :) matlab.ui.control.CheckBox

        % Listen for the AlgorithmChangedEvent from the model
        lhAlgorithmChangedEvent event.listener
    end
    
    properties (Dependent, Access = private)
        
        % cellstr of the selected PlotFcn values or set as '[]' from the model side
        SelectedValues % (1, :) cell or (1, :) char
    end
    
    % Set/get methods
    methods
        
        function set.SelectedValues(obj, selectedNames)
        
        % Indices of "checked"
        ind = num2cell(ismember({obj.Inputs.Tag}, selectedNames));
        
        % Set checkbox values
        [obj.Inputs.Value] = ind{:};
        end
        
        function value = get.SelectedValues(obj)
        
        % Plot fcn value names
        names = {obj.Inputs.Tag};
        
        % Indices of selected names
        ind = [obj.Inputs.Value];
        
        % Selected plot fcn values
        value = names(ind);
        end
    end
    
    methods (Access = public)
        
        function obj = PlotFcn(parentContainer)
        
        % Set view properties
        tag = 'PlotFcn';
        row = 2;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
            parentContainer, tag, row);
        end
        
        function updateView(obj, model, ~)
        
        % This method is called in the constructor and by the Optimize class on undo/redo.
        % It's also the listener callback for the AlgorithmChangedEvent in the Model.
        % Sets view to the current state of the Model
        
        % Update Model reference
        obj.Model = model;

        % Re-set listener on updated model reference
        delete(obj.lhAlgorithmChangedEvent);
        wrefObj = matlab.lang.WeakReference(obj);
        obj.lhAlgorithmChangedEvent = listener(obj.Model, 'AlgorithmChangedEvent', ...
            @(s,e)updateView(wrefObj.Handle,s,e));
        
        % Return names and labels for this solver's PlotFcn values
        [plotFcnNames, plotFcnLabels] = obj.Model.getPlotFcnNames;
        
        % If this solver has no PlotFcn option, hide the PlotFcn components
        % and exit the method
        if isempty(plotFcnNames)
            
            % Hide PlotFcn by setting RowHeight to 0
            obj.ParentContainer.RowHeight{obj.Row} = 0;
            return
        end
        
        % Show PlotFcn
        obj.ParentContainer.RowHeight{obj.Row} = 'fit';
        
        % Set the PlotFcn components
        obj.setPlotFcnComponents(plotFcnNames, plotFcnLabels);
        
        % Set the view from the model's value
        obj.SelectedValues = obj.Model.getPlotFcnValue();
        end
    end
    
    methods (Access = protected)
        
        function createComponents(obj)
        
        % Label
        obj.Label = uilabel(obj.ParentContainer);
        obj.Label.Layout.Row = obj.Row;
        obj.Label.Layout.Column = 1;
        obj.Label.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'Plot');
        obj.Label.VerticalAlignment = 'top';
        
        % Grid
        obj.Grid = uigridlayout(obj.ParentContainer);
        obj.Grid.Layout.Row = obj.Row;
        obj.Grid.Layout.Column = 2;
        obj.Grid.Padding = [0, 0, 0, 0];
        obj.Grid.ColumnWidth = {'fit', 'fit', 'fit', 'fit'};
        obj.Grid.RowHeight = {'fit'};
        end
        
        function valueChanged(obj, ~, ~)
        
        % Callback for checking/unchecking any PlotFcn values
        
        % Set model's PlotFcn option value
        obj.Model.setPlotFcnValue(obj.SelectedValues);
        
        % Notify listeners that the user has updated the task
        notify(obj, 'ValueChangedEvent')
        end
    end
    
    methods (Access = private)
        
        function setPlotFcnComponents(obj, plotFcnNames, plotFcnLabels)

        % Called by the updateView method of this class to ensure the correct
        % number of checkboxes and set labels/names

        % Ensure the expected number of checkboxes
        numInputs = numel(obj.Inputs);
        numInputsNeeded = numel(plotFcnLabels);
        if numInputs > numInputsNeeded
            % Remove
            notNeededInd = numInputsNeeded+1:numInputs;
            delete(obj.Inputs(notNeededInd));
            obj.Inputs(notNeededInd) = [];
        elseif numInputs < numInputsNeeded
            % Create
            perRow = 4;
            for count = numInputs+1:numInputsNeeded
                obj.Inputs(count) = uicheckbox(obj.Grid);
                obj.Inputs(count).Layout.Row = ceil(count / perRow);
                obj.Inputs(count).Layout.Column = count - ((obj.Inputs(count).Layout.Row - 1) * perRow);
                obj.Inputs(count).ValueChangedFcn = @obj.valueChanged;
            end
        end

        % Set labels/names
        [obj.Inputs.Text] = plotFcnLabels{:};
        [obj.Inputs.Tag] = plotFcnNames{:};

        % Set all row heights to 'fit;
        obj.Grid.RowHeight = repmat({'fit'}, 1, numel(obj.Grid.RowHeight));
        end
    end
end
