classdef Options < matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp
    % The Options view class manages the widgets for the solver options
    % section of the solver-based Optimize LET

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (Hidden, GetAccess = public, SetAccess = protected)

        % Grid for components
        SolverOptionsGrid (1, 1) matlab.ui.container.GridLayout

        % Message for fmincon and fminunc trust-region-reflective algorithm
        AlgorithmMessage (1, 1) matlab.ui.control.Label

        % Row in SolverOptionsGrid for AlgorithmMessage
        AlgorithmMessageRow (1, 1) double = 1;

        % Grid for components
        Grid (1, 1) matlab.ui.container.GridLayout

        % Button with the text 'Add'. Visible when no options are being viewed
        InitialAddButton (1, 1) matlab.ui.control.Button

        % DropDown to set the option category
        CategoryDropDown (1, :) matlab.ui.control.DropDown

        % DropDown adjacent to CategoryDropDown. Sets an available option
        % for the specified category
        OptionDropDown (1, :) matlab.ui.control.DropDown

        % Widget adajcent to OptionDropDown. Sets input of the specified option name
        Inputs (1, :) matlab.ui.control.internal.model.ComponentModel

        % Image to add a new option row
        AddImage (1, :) matlab.ui.control.Image

        % Image to delete an option row
        DeleteImage (1, :) matlab.ui.control.Image

        % Grid ColumnWidth when options are viewed
        OptionsViewedColumnWidth (1, :) cell = {matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth, ...
            0, 'fit', 'fit', 'fit', matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth, ...
            matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth};

        % Grid ColumnWidth when no options are viewed
        NoOptionsViewedColumnWidth (1, :) cell = {matlab.internal.optimgui.optimize.OptimizeConstants.ImageGridWidth, ...
            'fit', 0, 0, 0, 0, 0};

        % Listeners
        lhAlgorithmChangedEvent event.listener
    end

    properties (Dependent, Access = public)

        % Depends on the number of CategoryDropDowns
        NumberOfRows (1, 1) double
    end

    % get methods
    methods
        function value = get.NumberOfRows(obj)
            value = numel(obj.CategoryDropDown);
        end
    end

    methods (Access = public)

        function obj = Options(parentContainer)

            % Set view properties
            tag = 'SolverOptions';

            % Call superclass constructor
            obj@matlab.internal.optimgui.optimize.views.AbstractTaskViewWithHelp(...
                parentContainer, tag);
        end

        function updateView(obj, model, ~)

            % This method is called in the constructor, by the Optimize class everytime the SolverModel
            % changes and on undo/redo. It's also the listener callback for the AlgorithmChangedEvent
            % in the Model. It sets the view to the current state of the Model.

            % Update Model reference
            obj.Model = model;

            % Re-set listener on updated model reference
            delete(obj.lhAlgorithmChangedEvent);
            wrefObj = matlab.lang.WeakReference(obj);
            obj.lhAlgorithmChangedEvent = listener(obj.Model, 'AlgorithmChangedEvent', ...
                @(s,e)updateView(wrefObj.Handle,s,e));

            % If this solver has no options to view, reset the options view and exit the method
            if isempty(obj.Model.ViewedOptionNames)
                obj.resetView();
                return
            end

            % Make more rows, if needed
            while obj.NumberOfRows < numel(obj.Model.ViewedOptionNames)
                obj.makeRow();
            end

            % Are there any options to delete?
            indDelete = find(~ismember({obj.Inputs.Tag}, obj.Model.ViewedOptionNames));
            delete(obj.Inputs(indDelete));
            obj.Inputs(indDelete) = [];

            % Are there any new options to view?
            indAdd = find(~ismember(obj.Model.ViewedOptionNames', {obj.Inputs.Tag}));
            for ind = reshape(indAdd, 1, [])

                % Option to add
                [optionName, optionTable] = obj.sharedUpdateViewAddCommon(ind);

                % Make new input control
                obj.makeInput(ind, optionTable);

                % Set input value from model value
                obj.updateOptionValue(obj.Inputs(ind), obj.Model.getOptionValue(optionName));
            end

            % The elements of obj.Inputs are in the order to be viewed.
            % Set inputs to the correct rows in the grid. For example, if there
            % 5 inputs, and rows 2 and 3 got deleted, we need to move the inputs
            % from rows 4 and 5 up
            obj.reorderRows(min([indDelete, indAdd]), [], []);

            % Update button and image Visible/Enable properties. When switching solvers
            % or algorithms, it's possible that there are no more available options now
            obj.updateButtonVisibleEnable(obj.Model.AvailableCategoryNames);

            % Make sure right Grid rows are visible
            obj.updateGridVisibility();

            % Some options were common between solvers or between undo/redo states
            % Need to update these values for undo/redo, or if values are not valid
            % across solvers. For example, fmincon cannot have it's Alogorithm value be
            % Dual-Simplex, even though that's a valid Algorithm value for linprog
            commonInd = setdiff(1:numel(obj.Inputs), indAdd);
            for ind = commonInd

                % Option to set
                [optionName, optionTable] = obj.sharedUpdateViewAddCommon(ind);

                % Sometimes, we want to change the widget used for a given option.
                % Else, update the WidgetProperties of the existing widget
                if ~strcmp(optionTable.Widget{:}, class(obj.Inputs(ind)))

                    % Delete old input
                    delete(obj.Inputs(ind));
                    obj.Inputs(ind) = [];

                    % Make new input
                    obj.makeInput(ind, optionTable);
                else
                    for count = 1:2:numel(optionTable.WidgetProperties{:})
                        obj.Inputs(ind).(optionTable.WidgetProperties{:}{count}) = ...
                            optionTable.WidgetProperties{:}{count + 1};
                    end
                end

                % Set input value from model value
                obj.updateOptionValue(obj.Inputs(ind), obj.Model.getOptionValue(optionName));
            end

            % Update all category items
            obj.updateCategoryDropDownItems(obj.Model.AvailableCategoryNames);

            % For each option category viewed, update the OptionDropDown Items and ItemsData properties for that category
            viewedCategories = unique({obj.CategoryDropDown(1:numel(obj.Inputs)).Value});
            for count = 1:numel(viewedCategories)
                obj.updateOptionDropDownItems(viewedCategories{count});
            end

            % Order options structure fields
            obj.Model.sortOptionsStateStructFields({obj.Inputs.Tag});

            % Set visibility of AlgorithmMessage
            obj.setAlgorithmMessageVisibility();
        end

        function updateAlgorithmSelections(obj, ~, ~)

            % Called by the solver-based Optimize class when the ConstraintType
            % changes. Also called by the problem-based Optimize task in the
            % post-execution update to account for changes in the constraint type

            % Quick return if the valid algorithms have not changed
            if ~obj.Model.updateValidAlgorithms()
                return
            end

            % Special handling required for lsqnonlin/lsqcurvefit
            isLsqNonl = any(strcmp(obj.Model.OptimOptions.SolverName, {'lsqnonlin', 'lsqcurvefit'}));

            % For most solvers, only need to do something if the Algorithm dropdown is being viewed
            if ~isLsqNonl && obj.Model.isAlgorithmViewed

                % Find ind of the Algorithm dropdown input
                ind = strcmp('Algorithm', {obj.Inputs.Tag});

                % Store current value
                refValue = obj.Inputs(ind).Value;

                % Update dropdown items
                obj.Inputs(ind).Items = obj.Model.ValidAlgorithms;

                % If the current value is no longer valid, set Model to the default
                % Algorithm. Note that if the current Algorithm is still valid, it will remain the
                % current value. Otherwise, the value will reset to the first element in the
                % Model.ValidAlgorithms cellstr, which will be the default Algorithm
                if ~strcmp(refValue, obj.Inputs(ind).Value)
                    obj.Model.setOptionValue('Algorithm', obj.Inputs(ind).Value);
                    obj.Model.algorithmChanged();
                end
            
            elseif isLsqNonl

                % Even if the algorithm option is not viewed, any changes to the
                % valid algorithms need to be pushed for cnls because
                % the default algorithm may have been changed automatically
                % based on updates to the constraint type. If the default
                % algorithm changes, any options set to be viewed that are only
                % associated with that default algorithm need to be accounted for.
                obj.Model.algorithmChanged();
            end
        end
    end

    methods (Access = protected)

        function createComponents(obj)

            % SolverOptionsGrid
            obj.SolverOptionsGrid = uigridlayout(obj.ParentContainer);
            obj.SolverOptionsGrid.RowHeight = {0, 'fit'};
            obj.SolverOptionsGrid.ColumnWidth = {'fit'};

            % Label
            obj.AlgorithmMessage = uilabel(obj.SolverOptionsGrid);
            obj.AlgorithmMessage.Layout.Row = obj.AlgorithmMessageRow;
            obj.AlgorithmMessage.Layout.Column = 1;
            obj.AlgorithmMessage.Text = '';

            % Grid
            obj.Grid = uigridlayout(obj.SolverOptionsGrid);
            % Columns: 1) CshImage, 2) AddButton, 3) CategoryDropDown, 4) OptionDropDown,
            % 5) Inputs, 6) AddImage, 7) DeleteImage
            % Only show AddButton on construction
            obj.Grid.Layout.Row = 2;
            obj.Grid.Layout.Column = 1;
            obj.Grid.ColumnWidth = obj.NoOptionsViewedColumnWidth;
            obj.Grid.RowHeight = [{obj.RowHeight}, repmat({0}, 1, obj.NumberOfRows - 1)];
            obj.Grid.Padding = [0, 0, 0, 0];

            % CshImage
            parent = obj.Grid;
            row = 1;
            col = 1;
            tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'optionsLink');
            tag = 'SolverOptionsHelpIcon';
            obj.createHelpIcon(parent, row, col, tooltip, tag);
        
            % InitialAddButton
            obj.InitialAddButton = uibutton(obj.Grid, 'push');
            obj.InitialAddButton.Layout.Row = 1;
            obj.InitialAddButton.Layout.Column = 2;
            obj.InitialAddButton.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'add');
            obj.InitialAddButton.ButtonPushedFcn = @obj.addPushed;
            obj.InitialAddButton.Tag = 'OptionsInitialAddButton';

            % Make 1 row of dropdowns and add/delete uiimages
            obj.makeRow();
        end

        function valueChanged(obj, src, event)

            % Callback when the user changes any input value

            % Row being changed
            ind = src.Layout.Row;

            % Option being changed
            optionName = obj.OptionDropDown(ind).Value;

            % New option value
            value = obj.Inputs(ind).Value;

            % If the option value cannot be set, reset to the previous value
            if ~obj.Model.setOptionValue(optionName, value)
                obj.updateOptionValue(src, event.PreviousValue);
            end

            % Was the algorithm just changed
            obj.checkAlgorithmChanged(optionName);

            % Notify listeners that the user has updated the task
            notify(obj, 'ValueChangedEvent')
        end

        function cshImageClicked(obj, ~, ~)

            % Callback when the user clicks the CshImage

            % Include doc link with eventData
            docLink = [obj.Model.OptimOptions.SolverName, 'Options'];
            eventData = matlab.internal.optimgui.optimize.OptimizeEventData(docLink);
            notify(obj, 'CshImageClickedEvent', eventData);
        end

        function addPushed(obj, src, ~)

            % Callback when the user clicks InitialAddButton or AddImage components

            % Next option info. If next option is not available, exit the method
            % Here to guard against user double-clicking addOption button when
            % only one option is left to add
            try
                nextOptionTable = obj.Model.getNextOptionTable();
            catch
                return
            end

            % Add the nextOption to the OptionsModel
            obj.Model.addOption(nextOptionTable.Row{:});

            % If there are no options viewed, make InitialAddButton invisible and add to row 1
            % Else, add to row below the clicked AddImage
            if numel(obj.Inputs) == 0
                obj.Grid.ColumnWidth = obj.OptionsViewedColumnWidth;
                ind = 1;
            else
                ind = src.Layout.Row + 1;
            end

            % Make more rows, if needed
            while obj.NumberOfRows < numel(obj.Model.ViewedOptionNames)
                obj.makeRow();
            end

            % Make new input control
            obj.makeInput(ind, nextOptionTable);

            % Because row insertion is allowed, need to move all existing inputs below
            % the newly added row down one row. Also need to move down the Items/ItemsData
            % of the dropdowns
            if ind < numel(obj.Inputs)
                obj.reorderRows(ind, ind:numel(obj.Inputs) - 1, ind + 1:numel(obj.Inputs));
            end

            % Make sure the correct rows are visible
            obj.updateGridVisibility();

            % If there are no more available options, disable AddImage
            if isempty(obj.Model.AvailableCategoryNames)
                [obj.AddImage.Enable] = deal('off');
            end

            % Set Items and ItemsData of dropdowns from nextOptionTable
            obj.CategoryDropDown(ind).Items = nextOptionTable.Category;
            obj.OptionDropDown(ind).Items = nextOptionTable.DisplayLabel;
            obj.OptionDropDown(ind).ItemsData = nextOptionTable.Row;
            obj.OptionDropDown(ind).Tooltip = nextOptionTable.Tooltip{:};

            % Update the DropDown Items and ItemsData properties of other dropdowns.
            % For example, all other viewed options of the same category need to have
            % the newly viewed option removed from their Items list
            obj.updateDropDownItems(nextOptionTable.Category{:})

            % Order options structure fields
            obj.Model.sortOptionsStateStructFields({obj.Inputs.Tag});

            % Notify listeners that the user has updated the task
            notify(obj, 'ValueChangedEvent')
        end

        function deletePushed(obj, src, ~)

            % Callback when the users clicks DeleteImage components

            % ind being deleted
            ind = src.Layout.Row;

            % Get option and category names from deleted row
            oldOptionName = obj.OptionDropDown(ind).Value;
            oldCategoryName = obj.CategoryDropDown(ind).Value;

            % Delete specified row input, or exit the method on error
            % Here to guard against user double-clicking deleteOption button when
            % only one option is left to delete
            try
                obj.deleteOption(oldOptionName, ind);
            catch
                return
            end

            % Enable AddImage if disabled, can't still be maxed out
            if strcmp(obj.AddImage(1).Enable, 'off')
                [obj.AddImage.Enable] = deal('on');
            end

            % Need to move all existing inputs into the right row. Also, need to
            % update ItemsItemsData of the dropdowns
            if ind <= numel(obj.Inputs)
                obj.reorderRows(ind, ind + 1:numel(obj.Inputs) + 1, ind:numel(obj.Inputs));
            end

            % Make sure the correct rows are visible
            obj.updateGridVisibility();

            % Make InitialAddButton visible if no options are being viewed anymore
            if numel(obj.Inputs) == 0
                obj.Grid.ColumnWidth = obj.NoOptionsViewedColumnWidth;
            end

            % Update the DropDown Items and ItemsData properties of other dropdowns
            obj.updateDropDownItems(oldCategoryName)

            % Was the algorithm just deleted?
            obj.checkAlgorithmChanged(oldOptionName);

            % Notify listeners that the user has updated the task
            notify(obj, 'ValueChangedEvent')
        end

        function categoryChanged(obj, src, event)

            % Callback when the user changes an option category

            % ind being changed
            ind = src.Layout.Row;

            % Previous category name
            oldCategoryName = event.PreviousValue;

            % New category name
            newCategoryName = obj.CategoryDropDown(ind).Value;

            % Previous option name. Since the category is new, the option has to be new as well
            oldOptionName = obj.OptionDropDown(ind).Value;

            % Delete previous option
            obj.deleteOption(oldOptionName, ind);

            % Next option info for the new category
            nextOptionTable = obj.Model.getNextOptionTable(newCategoryName);

            % Add the nextOption to the OptionsModel
            obj.Model.addOption(nextOptionTable.Row{:});

            % Make new input control
            obj.makeInput(ind, nextOptionTable);

            % Set Value of options dropdown from nextOptionTable
            obj.OptionDropDown(ind).Items = nextOptionTable.DisplayLabel;
            obj.OptionDropDown(ind).ItemsData = nextOptionTable.Row;
            obj.OptionDropDown(ind).Tooltip = nextOptionTable.Tooltip{:};

            % Update the OptionDropDown Items and ItemsData properties for options related to the old category
            obj.updateOptionDropDownItems(oldCategoryName);

            % Shared method calls
            obj.sharedCategoryOptionChanged(oldOptionName, nextOptionTable.Category{:});
        end

        function optionChanged(obj, src, event)

            % Callback when the user changes an option name/type

            % ind being changed
            ind = src.Layout.Row;

            % Previous option name
            oldOptionName = event.PreviousValue;

            % Delete previous option
            obj.deleteOption(oldOptionName, ind);

            % Next option name
            nextOptionName = obj.OptionDropDown(ind).Value;

            % Next option info
            nextOptionTable = obj.Model.getOptionTable(nextOptionName);

            % Add the nextOption to the model
            obj.Model.addOption(nextOptionTable.Row{:});

            % Make new input control
            obj.makeInput(ind, nextOptionTable);

            % Set tooltip
            obj.OptionDropDown(ind).Tooltip = nextOptionTable.Tooltip{:};

            % Shared method calls
            obj.sharedCategoryOptionChanged(oldOptionName, nextOptionTable.Category{:});
        end

        function sharedCategoryOptionChanged(obj, oldOptionName, categoryName)

            % Called by categoryChanged and optionChanged methods, shared method calls and sequencing

            % Update the DropDown Items and ItemsData properties
            obj.updateDropDownItems(categoryName)

            % Order options structure fields
            obj.Model.sortOptionsStateStructFields({obj.Inputs.Tag});

            % Was the algorithm just removed
            obj.checkAlgorithmChanged(oldOptionName);

            % Notify listeners that the user has updated the task
            notify(obj, 'ValueChangedEvent')
        end

        function makeRow(obj)
            % CategoryDropDown
            obj.makeDropDown(3, @obj.categoryChanged, ...
                matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'optionsCategory'), ...
                'CategoryDropDown');

            % OptionDropDown
            obj.makeDropDown(4, @obj.optionChanged, '', 'OptionDropDown');

            % DeleteImage
            obj.makeImage('Delete', 'deletedStatus', 6, @obj.deletePushed);

            % AddImage
            obj.makeImage('Add', 'addedStatus', 7, @obj.addPushed);
        end

        function makeDropDown(obj, col, callback, tooltip, propName)

            % Called by createComponents method. Makes a new CategoryDropDown or OptionDropDown
            % depending on propName input argument

            h = uidropdown(obj.Grid);
            h.ValueChangedFcn = callback;
            h.Tooltip = tooltip;
            h.Tag = propName;
            h.Items = cell(0);
            h.Layout.Row = numel(obj.(propName)) + 1;
            h.Layout.Column = col;
            obj.(propName) = [obj.(propName), h];
        end

        function h = makeInput(obj, row, optionTable)

            % Called by updateView, addPushed, categoryChanged, and optionChanged methods.
            % Makes new input widget for option table input argument

            if strcmp(optionTable.Widget{:}, 'matlab.ui.control.internal.model.WorkspaceDropDown')
                h = feval(optionTable.Widget{:}, 'Parent', obj.Grid, 'UseDefaultAsPlaceholder', true);
                for count = 1:2:numel(optionTable.WidgetProperties{:})
                    h.(optionTable.WidgetProperties{:}{count}) = optionTable.WidgetProperties{:}{count + 1};
                end
            else
                h = feval(optionTable.Widget{:}, 'Parent', obj.Grid, optionTable.WidgetProperties{:}{:});
            end
            h.Layout.Row = row;
            h.Layout.Column = 5;
            h.Value = optionTable.DefaultValue{:};
            h.ValueChangedFcn = @(src, event)obj.valueChanged(src, event);
            h.Tag = optionTable.Row{:};
            before_ind = 1:numel(obj.Inputs) < h.Layout.Row;
            after_ind = 1:numel(obj.Inputs) >= h.Layout.Row;
            obj.Inputs = [obj.Inputs(before_ind), h, obj.Inputs(after_ind)];
        end

        function makeImage(obj, id, iconID, col, callback)

            % Called by createComponents method. Appends new AddImage or DeleteImage component
            % depending on id input argument

            h = uiimage(obj.Grid);
            h.ImageClickedFcn = callback;
            matlab.ui.control.internal.specifyIconID(h, iconID, 16, 16);
            h.Interruptible = 'off';
            h.BusyAction = 'cancel';
            h.Layout.Row = numel(obj.([id, 'Image'])) + 1;
            h.Layout.Column = col;
            h.Tag = [id, 'Option'];
            obj.([id, 'Image']) = [obj.([id, 'Image']), h];
        end

        function deleteOption(obj, optionName, row)

            % Called by deletePushed, categoryChanged, and optionChanged methods.
            % Removes an option from the model and deletes the options's view widget

            % Remove option from model
            obj.Model.removeOption(optionName);

            % Delete option input
            delete(obj.Inputs(row));
            obj.Inputs(row) = [];
        end

        function checkAlgorithmChanged(obj, optionName)

            if strcmp(optionName, 'Algorithm')

                % Processing for when the algorithm changes
                obj.Model.algorithmChanged();
            end
        end

        function reorderRows(obj, ind, oldInd, newInd)

            % Called by addPushed and deletePushed methods

            % Move the option inputs into the correct row in the grid
            for count =  ind:numel(obj.Inputs)
                obj.Inputs(count).Layout.Row = count;
            end

            % DropDown properties that need to move indices
            category = num2cell({obj.CategoryDropDown(oldInd).Value});
            optionItems = {obj.OptionDropDown(oldInd).Items};
            optionItemsData = {obj.OptionDropDown(oldInd).ItemsData};
            optionValue = {obj.OptionDropDown(oldInd).Value};
            optionTooltip = {obj.OptionDropDown(oldInd).Tooltip};

            % Set properties in new indices
            [obj.CategoryDropDown(newInd).Items] = deal(category{:});
            [obj.OptionDropDown(newInd).Items] = deal(optionItems{:});
            [obj.OptionDropDown(newInd).ItemsData] = deal(optionItemsData{:});
            [obj.OptionDropDown(newInd).Value] = deal(optionValue{:});
            [obj.OptionDropDown(newInd).Tooltip] = deal(optionTooltip{:});
        end

        function updateGridVisibility(obj)

            % Show all rows with an Input, hide all others
            visibleRows = 1:max([1, numel(obj.Inputs)]);
            hiddenRows = visibleRows(end) + 1:obj.NumberOfRows;
            obj.Grid.RowHeight(visibleRows) = {obj.RowHeight};
            obj.Grid.RowHeight(hiddenRows) = {0};

            % Empty the items of unviewed DropDowns
            [obj.CategoryDropDown(hiddenRows).Items] = deal(cell(0));
            [obj.OptionDropDown(hiddenRows).Items] = deal(cell(0));
            [obj.OptionDropDown(hiddenRows).ItemsData] = deal(cell(0));
            [obj.OptionDropDown(hiddenRows).Tooltip] = deal('');
        end

        function updateDropDownItems(obj, categoryName)

            % Called by addPushed, deletePushed, and sharedCategoryOptionChanged methods.
            % Sets the category and option dropdown items

            % Set Items of all CategoryDropDowns
            obj.updateCategoryDropDownItems(obj.Model.AvailableCategoryNames);

            % Update the OptionDropDown Items and ItemsData properties for the specified category
            obj.updateOptionDropDownItems(categoryName);
        end

        function updateCategoryDropDownItems(obj, availableCategories)

            % Called by updateView and updateDropDownItems methods

            % For each CategoryDropDown, append availableCategories to its current Value and set to Items property
            for count =  1:numel(obj.Inputs)
                obj.CategoryDropDown(count).Items = unique([obj.CategoryDropDown(count).Value, availableCategories], 'stable');
            end
        end

        function updateOptionDropDownItems(obj, categoryName)

            % Called by updateView, categoryChanged, and updateDropDownItems methods

            % For each option dropdown of the given category, append availableOption Labels and availableOptionNames
            % to its current Item and Value and set to Items and Items Data properties
            [availableOptionNames, availableOptionLabels] = obj.Model.getRemainingOptionsForCategory(categoryName);
            rows = find(strcmp({obj.CategoryDropDown.Value}, categoryName));
            for count = rows
                ind = strcmp(obj.OptionDropDown(count).ItemsData, obj.OptionDropDown(count).Value);
                obj.OptionDropDown(count).Items = [obj.OptionDropDown(count).Items(ind), availableOptionLabels];
                obj.OptionDropDown(count).ItemsData = [obj.OptionDropDown(count).Value, availableOptionNames];
            end
        end

        function resetView(obj)

            % Called by updateView method when there are no options to view

            % Delete all Inputs
            delete(obj.Inputs(:));
            obj.Inputs(:) = [];

            % Update the row and column visibility of the Grid
            obj.updateGridVisibility();

            % Show InitalAddButton, hide all other components
            obj.Grid.ColumnWidth = obj.NoOptionsViewedColumnWidth;

            % Enable AddImage if disabled, can't still be maxed out
            if strcmp(obj.AddImage(1).Enable, 'off')
                [obj.AddImage.Enable] = deal('on');
            end

            % Hide any Algorithm message
            obj.SolverOptionsGrid.RowHeight{obj.AlgorithmMessageRow} = 0;
        end

        function updateButtonVisibleEnable(obj, moreAvailableList)

            % Called by updateView method.

            % Make InitialAddButton invisible
            obj.Grid.ColumnWidth = obj.OptionsViewedColumnWidth;

            % Disable AddImage if maxed out, or enable if previously maxed out
            if isempty(moreAvailableList)
                [obj.AddImage.Enable] = deal('off');
            else
                [obj.AddImage.Enable] = deal('on');
            end
        end

        function [optionName, optionTable] = sharedUpdateViewAddCommon(obj, ind)

            % Called by updateView method. Shared method calls and sequencing when adding
            % options to view or setting common options across solvers for undo/redo

            % Option name to view
            optionName = obj.Model.ViewedOptionNames{ind};

            % Option info
            optionTable = obj.Model.getOptionTable(optionName);

            % Set items
            obj.CategoryDropDown(ind).Items = optionTable.Category;
            obj.OptionDropDown(ind).Items = optionTable.DisplayLabel;
            obj.OptionDropDown(ind).ItemsData = optionTable.Row;
            obj.OptionDropDown(ind).Tooltip = optionTable.Tooltip{:};
        end

        function setAlgorithmMessageVisibility(obj)

            % If the solver is fmincon OR fminunc AND Algorithm contains 'trust-region' pattern, show message
            % Else, hide the message
            if any(strcmp(obj.Model.OptimOptions.SolverName, {'fmincon', 'fminunc'})) && ...
                    contains(obj.Model.OptimOptions.Algorithm, 'trust-region')
                obj.AlgorithmMessage.Text = getString(message('MATLAB:optimfun_gui:Labels:AlgorithmMessage', ...
                    obj.Model.OptimOptions.Algorithm));
                obj.SolverOptionsGrid.RowHeight{obj.AlgorithmMessageRow} = 'fit';
            else
                obj.SolverOptionsGrid.RowHeight{obj.AlgorithmMessageRow} = 0;
            end
        end
    end

    methods (Static, Access = protected)

        function updateOptionValue(src, value)

            % Called by updateView and valueChanged methods

            % Set option input Value property
            if isa(src, 'matlab.ui.control.internal.model.WorkspaceDropDown')
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(src, value);
            else
                src.Value = value;
            end
        end
    end
end
