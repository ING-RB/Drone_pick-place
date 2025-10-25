classdef Constraints < matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp
    % The Constraints view class manages the widgets for the constraints
    % section of the solver-based Optimize LET

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)

        % For alignment purposes, place SectionLabel in its own grid
        SectionLabelGrid (1, 1) matlab.ui.container.GridLayout

        % Constraint section label
        SectionLabel (1, 1) matlab.ui.control.Label

        % Grid for components
        SectionGrid (1, 1) matlab.ui.container.GridLayout

        % For alignment purposes, place ConstraintsRequiredLabel in its own grid
        ConstraintsRequiredGrid (1, 1) matlab.ui.container.GridLayout
        
        % Message when constraints are required
        ConstraintsRequiredLabel (1, 1) matlab.ui.control.Label

        % Grid for inputs
        Grid (1, 1) matlab.ui.container.GridLayout

        % For alignment purposes, place NonlinearConstraintsFcn label in its own grid
        NonlinearConstraintsFcnLabelGrid (1, 1) matlab.ui.container.GridLayout

        % Label for specific constraints (Lower bounds, Linear inequality,...)
        InputLabels (1, :) matlab.ui.control.Label

        % For alignment purposes, put each input in its own grid
        InputGrids (1, :) matlab.ui.container.GridLayout

        % Inputs
        OrderedConstraintNames (1, :) cell = reshape(setdiff(...
            matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ConstraintKeys, ...
            {'Unsure', 'None'}, 'stable'), 1, []);
        LowerBounds matlab.internal.optimgui.optimize.solverbased.views.inputs.BoundsConstraintView
        UpperBounds matlab.internal.optimgui.optimize.solverbased.views.inputs.BoundsConstraintView
        LinearInequality matlab.internal.optimgui.optimize.solverbased.views.inputs.LinearConstraintView
        LinearEquality matlab.internal.optimgui.optimize.solverbased.views.inputs.LinearConstraintView
        SecondOrderCone matlab.internal.optimgui.optimize.solverbased.views.inputs.ArrayInputView
        NonlinearConstraintFcn matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionView
        IntegerConstraint matlab.internal.optimgui.optimize.solverbased.views.inputs.ArrayInputView

        % For alignment purposes, place NonlinearConstraintFcn CshImage in its own grid
        CshGrid (1, 1) matlab.ui.container.GridLayout

        % Listen for changes to Inputs
        lhInputChanged event.listener
    end

    properties (Dependent, Access = private)

        % The number of rows required in Grid
        NumberOfGridRows (1, 1) double
    end

    methods

        function value = get.NumberOfGridRows(obj)

        % The number of Grid rows is equal to the number of constraints
        value = numel(obj.OrderedConstraintNames);
        end
    end

    methods (Access = public)

        function obj = Constraints(parentContainer)

        % Set view properties
        tag = 'Constraints';
        row = 3;
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp(...
            parentContainer, tag, row);
        end

        function updateView(obj, model)

        % This method is called in the constructor, by the Optimize class everytime the SolverModel
        % changes, and on undo/redo. It sets the view to the current state of the Model

        % Update Model reference
        obj.Model = model;

        % If this solver has no constraints, hide the entire constraints section and exit the method
        if isempty(obj.Model.Constraints)

            % Hide section by setting parent container RowHeight and InputGrids widths to 0
            obj.ParentContainer.RowHeight{obj.Row} = 0;
            [obj.InputGrids.ColumnWidth] = deal({0, 0});

            % Empty Label so column width is only influenced by visible labels
            obj.SectionLabel.Text = '';
            return
        end

        % Loop through this solver's constraints
        for ct = 1:numel(obj.Model.Constraints)

            % Current constraint
            thisConstraint = obj.Model.Constraints{ct};

            % If the widget is already created, update its properties,
            % Else, make the widget if necessary
            if ~isempty(obj.(thisConstraint))
                obj.updateConstraintWidget(thisConstraint);
            elseif any(strcmp(thisConstraint, obj.Model.SelectedConstraintNames))
                obj.makeConstraintWidget(thisConstraint);
            end
        end

        % Set the row visibilty of obj.Grid
        obj.updateGridVisibility();
        end

        function obj = resetConstraints(obj, constraintsList)

        % Called by Optimize view class when the user removes constraints using
        % the state buttons

        % Loop through the deleted constraints. Can only delete constraints that
        % exist for the solver: this is necessary to allow users to toggle constraint
        % types when they don't have a required license
        constraintsToReset = intersect(constraintsList, obj.Model.Constraints);
        for ct = 1:numel(constraintsToReset)

            % Current constraint
            thisConstraint = constraintsToReset{ct};

            % Reset model value
            obj.Model.(thisConstraint).Value = ...
                obj.Model.(thisConstraint).DefaultValue;

            % Update the constraint view
            obj.updateConstraintWidget(thisConstraint);
        end
        end

        function makeConstraintWidget(obj, constraint)

        % Index of this constraint's widget in the view
        ind = find(strcmp(obj.OrderedConstraintNames, constraint));

        % Make this constraint's view components
        obj.makeInput(ind, constraint);

        % Update the properties of this constraint's widget
        obj.updateConstraintWidget(constraint);

        % Reset sub-views listeners for user inputs
        delete(obj.lhInputChanged);
        wrefObj = matlab.lang.WeakReference(obj);
        fun = @(x) listener(x, 'ValueChangedEvent', @(s,e)valueChanged(wrefObj.Handle,s,e));
        obj.lhInputChanged = arrayfun(fun, [obj.LowerBounds, obj.UpperBounds, ...
            obj.LinearInequality, obj.LinearEquality, obj.SecondOrderCone, ...
            obj.NonlinearConstraintFcn, obj.IntegerConstraint]);
        end

        function updateConstraintWidget(obj, constraint)

        % Update constraint view
        obj.(constraint).updateView(obj.Model.(constraint));
        end
        
        function updateGridVisibility(obj)

        % This method is called by the updateView method of this class and by the
        % updateConstraintsGrid method of the Optimize class. It makes sure the
        % right rows of the constraints grid are showing

        % If there are no viewed constraints AND no constraints are required,
        % hide entire constraints section and exit the method
        if isempty(obj.Model.SelectedConstraintNames) && isempty(obj.Model.ConstraintsRequiredMessage)

            % Hide section by setting parent container RowHeight and InputGrids widths to 0
            obj.ParentContainer.RowHeight{obj.Row} = 0;
            [obj.InputGrids.ColumnWidth] = deal({0, 0});

            % Empty Label so column width is only influenced by visible labels
            obj.SectionLabel.Text = '';
            return
        end

        % Set Label
        obj.SectionLabel.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'constraints');

        % Set/show constraints required message if necessary
        obj.ConstraintsRequiredLabel.Text = obj.Model.ConstraintsRequiredMessage;
        if isempty(obj.ConstraintsRequiredLabel.Text)
            obj.ConstraintsRequiredGrid.RowHeight{1} = 0;
        else
            obj.ConstraintsRequiredGrid.RowHeight{1} = obj.RowHeight;
        end
        
        % Start with a Grid row height of 0 for all rows
        rowHeights = repmat({0}, 1, obj.NumberOfGridRows);

        % Ensure selected constraints are visible
        viewedInd = ismember(obj.OrderedConstraintNames, obj.Model.SelectedConstraintNames);
        rowHeights(viewedInd) = {'fit'};
        columnWidths = repmat({{0, 0}}, 1, numel(viewedInd));
        columnWidths(viewedInd) = {{'fit', 'fit'}}; % element 1 is input, element 2 is potential help link
        obj.Grid.RowHeight = rowHeights;
        [obj.InputGrids.ColumnWidth] = columnWidths{:};

        % Set InputLabels, start empty so column width is only influenced by visible labels
        % Labels are the first column of obj.Grid
        inputLabels = repmat({''}, 1, numel(obj.OrderedConstraintNames));
        displayLabels = matlab.internal.optimgui.optimize.utils.getMessage('Labels', ...
            obj.OrderedConstraintNames);
        inputLabels(viewedInd) = displayLabels(viewedInd);
        [obj.InputLabels.Text] = inputLabels{:};

        % Show section by setting RowHeight to 'fit'
        obj.ParentContainer.RowHeight{obj.Row} = 'fit';
        end
    end

    methods (Access = protected)

        function createComponents(obj)

        % SectionLabelGrid
        obj.SectionLabelGrid = uigridlayout(obj.ParentContainer);
        obj.SectionLabelGrid.ColumnWidth = {'fit'};
        obj.SectionLabelGrid.RowHeight = {obj.RowHeight};
        obj.SectionLabelGrid.RowSpacing = 0;
        obj.SectionLabelGrid.Padding = [0, 0, 0, 0];
        obj.SectionLabelGrid.Layout.Row = obj.Row;
        obj.SectionLabelGrid.Layout.Column = 1;

        % SectionLabel
        obj.SectionLabel = uilabel(obj.SectionLabelGrid);
        obj.SectionLabel.Layout.Row = 1;
        obj.SectionLabel.Layout.Column = 1;
        obj.SectionLabel.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'constraints');
        obj.SectionLabel.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'Constraints');

        % SectionGrid
        obj.SectionGrid = uigridlayout(obj.ParentContainer);
        obj.SectionGrid.Layout.Row = obj.Row;
        obj.SectionGrid.Layout.Column = 2;
        obj.SectionGrid.RowHeight = {'fit', 'fit'};
        obj.SectionGrid.ColumnWidth = {'fit'};
        obj.SectionGrid.Padding = [0, 0, 0, 0];
        
        % ConstraintsRequiredGrid
        obj.ConstraintsRequiredGrid = uigridlayout(obj.SectionGrid);
        obj.ConstraintsRequiredGrid.Layout.Row = 1;
        obj.ConstraintsRequiredGrid.Layout.Column = 1;
        obj.ConstraintsRequiredGrid.RowHeight = {0};
        obj.ConstraintsRequiredGrid.ColumnWidth = {'fit'};
        obj.ConstraintsRequiredGrid.Padding = [0, 0, 0, 0];

        % ConstraintsRequiredLabel
        obj.ConstraintsRequiredLabel = uilabel(obj.ConstraintsRequiredGrid);
        obj.ConstraintsRequiredLabel.Layout.Row = 1;
        obj.ConstraintsRequiredLabel.Layout.Column = 1;
        obj.ConstraintsRequiredLabel.Text = '';

        % Grid
        obj.Grid = uigridlayout(obj.SectionGrid);
        obj.Grid.Layout.Row = 2;
        obj.Grid.Layout.Column = 1;
        obj.Grid.ColumnWidth = {'fit', 'fit'};
        obj.Grid.RowHeight = repmat({'fit'}, 1, obj.NumberOfGridRows);
        obj.Grid.Padding = [0, 0, 0, 0];

        % InputLabels and InputGrids
        for ct = 1:numel(obj.OrderedConstraintNames)
            constraint = obj.OrderedConstraintNames{ct};
            obj.makeConstraintLabel(ct, constraint);
            obj.makeInputGrid(ct);
        end

        % NonlinearConstraintFcn index in the grid
        ind = find(strcmp(obj.OrderedConstraintNames, 'NonlinearConstraintFcn'));

        % NonlinearConstraintsFcnLabelGrid
        obj.NonlinearConstraintsFcnLabelGrid = uigridlayout(obj.Grid);
        obj.NonlinearConstraintsFcnLabelGrid.ColumnWidth = {'fit'};
        obj.NonlinearConstraintsFcnLabelGrid.RowHeight = {obj.RowHeight};
        obj.NonlinearConstraintsFcnLabelGrid.RowSpacing = 0;
        obj.NonlinearConstraintsFcnLabelGrid.Padding = [0, 0, 0, 0];
        obj.NonlinearConstraintsFcnLabelGrid.Layout.Row = ind;
        obj.NonlinearConstraintsFcnLabelGrid.Layout.Column = 1;

        % Move NonlinearConstraintsFcn label to NonlinearConstraintsFcnLabelGrid
        obj.InputLabels(ind).Layout.Row = 1;
        obj.InputLabels(ind).Parent = obj.NonlinearConstraintsFcnLabelGrid;

        % CshGrid
        obj.CshGrid = uigridlayout(obj.InputGrids(ind));
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
        tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'constraintLink');
        tag = 'NonlinearConstraintFcn';
        obj.createHelpIcon(parent, row, col, tooltip, tag);
        end

        function cshImageClicked(obj, src, ~)

        % Callback when the user clicks the CshImage

        % Include doc link with eventData. Note only function widgets have
        % help links. Those widgets have a DocLinkID property
        fcnWidget = obj.(src.Tag);
        docLink = fcnWidget.Model.WidgetProperties.DocLinkID;
        eventData = matlab.internal.optimgui.optimize.OptimizeEventData(docLink);
        notify(obj, 'CshImageClickedEvent', eventData);
        end
    end

    methods (Access = private)

        function h = makeConstraintLabel(obj, ind, constraint)
        h = uilabel(obj.Grid);
        h.Layout.Row = ind;
        h.Layout.Column = 1;
        h.Text = '';
        h.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', constraint);
        obj.InputLabels(ind) = h;
        end

        function h = makeInputGrid(obj, ind)
        h = uigridlayout(obj.Grid);
        h.Layout.Row = ind;
        h.Layout.Column = 2;
        h.ColumnWidth = {'fit', matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth};
        h.RowHeight = {'fit'};
        h.Padding = [0, 0, 0, 0];
        obj.InputGrids(ind) = h;
        end

        function h = makeInput(obj, ind, constraint)
        widget = obj.Model.(constraint).Widget;
        h = feval(widget, obj.InputGrids(ind), constraint);
        obj.(constraint) = h;
        end
    end
end
