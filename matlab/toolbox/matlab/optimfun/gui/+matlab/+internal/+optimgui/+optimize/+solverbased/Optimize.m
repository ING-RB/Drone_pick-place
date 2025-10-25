classdef Optimize < matlab.internal.optimgui.optimize.AbstractOptimizeApproach
    % Manage the solver-based approach for the Optimize task
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Superclass abstract properties to implement
        Model % matlab.internal.optimgui.optimize.solverbased.models.OptimizeModel
        ParentContainerRowHeight = {0, 0, 'fit'};
        DefaultAutoRun = false;
        
        % Principle app container components
        UIAccordion (1, 1) matlab.ui.container.internal.Accordion
        ProblemTypeAccordionPanel (1, 1) matlab.ui.container.internal.AccordionPanel
        ProblemTypeGrid (1, 1) matlab.ui.container.GridLayout
        ProblemDataAccordionPanel (1, 1) matlab.ui.container.internal.AccordionPanel
        ProblemDataGrid (1, 1) matlab.ui.container.GridLayout
        SolverOptionsAccordionPanel (1, 1) matlab.ui.container.internal.AccordionPanel
        DisplayAccordionPanel (1, 1) matlab.ui.container.internal.AccordionPanel
        DisplayGrid (1, 1) matlab.ui.container.GridLayout

        % Sub-view objects manage the widgets and user inputs for certain
        % sections of the uifigure
        ObjectiveType matlab.internal.optimgui.optimize.solverbased.views.ObjectiveType
        ConstraintType matlab.internal.optimgui.optimize.solverbased.views.ConstraintType
        SelectSolver matlab.internal.optimgui.optimize.solverbased.views.SelectSolver
        ObjectiveFunction matlab.internal.optimgui.optimize.solverbased.views.ObjectiveFunction
        Solver matlab.internal.optimgui.optimize.solverbased.views.Solver
        Constraints matlab.internal.optimgui.optimize.solverbased.views.Constraints
        Options matlab.internal.optimgui.optimize.solverbased.views.Options
        TextDisplay matlab.internal.optimgui.optimize.solverbased.views.TextDisplay
        PlotFcn matlab.internal.optimgui.optimize.solverbased.views.PlotFcn

        % Listeners
        lhSolverList event.proplistener
        lhSolverName event.proplistener
        lhProblemTypeChanged event.proplistener
        lhConstraintTypeChanged event.proplistener
        lhRemoveConstraints event.listener
        lhUpdateConstraintsGrid event.listener

        % This property stores whether solver model related views are enabled
        % These views get disabled when user does not have a license for the
        % specified problem type
        areSolverModelViewsEnabled (1, 1) logical = true;
    end

    methods (Access = public)

        function app = Optimize(varargin)

            % Call superclass constructor
            app@matlab.internal.optimgui.optimize.AbstractOptimizeApproach(varargin{:});
        end

        function reset(app)

            % Reset all options
            app.Model.State.Options = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultOptionsStruct;
            app.Model.SolverModel.Options.setOptionsModel();
            app.Options.updateView(app.Model.SolverModel.Options);
            app.TextDisplay.updateView(app.Model.SolverModel.Options);
            app.PlotFcn.updateView(app.Model.SolverModel.Options);
        end
    end

    methods (Access = protected)

        function setup(app)

            % Turn auto-run off by default
            app.AutoRun = false;

            % Create default model object
            app.Model = matlab.internal.optimgui.optimize.solverbased.models.OptimizeModel();

            % Create task components
            app.createComponents();

            % Set view to match the model
            app.updateView();
            drawnow nocallbacks

            wrefApp = matlab.lang.WeakReference(app);
            % Listen for changes to the SolverList and SolverName Model properties
            app.lhSolverList = listener(app.Model, {'ObjectiveType', 'ConstraintType'}, ...
                'PostSet', @(s,e)SolverListChanged(wrefApp.Handle,s,e));
            app.lhSolverName = listener(app.Model, 'SolverName', 'PostSet', @(s,e)SolverNameChanged(wrefApp.Handle,s,e));

            % Listen for changes to the problem type buttons
            app.lhProblemTypeChanged = listener(app.Model, {'ObjectiveType', 'ConstraintType'}, ...
                'PostSet', @(s,e)ProblemTypeChanged(wrefApp.Handle,s,e));

            % Listen for changes to the constraint type. It may impact valid Algorithms
            app.lhConstraintTypeChanged = listener(app.Model, 'ConstraintType', 'PostSet', @(s,e)ConstraintTypeChanged(wrefApp.Handle,s,e));

            % Listen to sub-views for user inputs
            fun = @(x) listener(x, 'ValueChangedEvent', @(s,e)taskChanged(wrefApp.Handle,s,e));
            app.lhTaskChanged = arrayfun(fun, [app.ObjectiveType, app.ConstraintType, app.SelectSolver, ...
                app.ObjectiveFunction, app.Solver, app.Constraints, app.Options, ...
                app.TextDisplay, app.PlotFcn]);

            % Listen to the ConstraintType class for removed constraints
            app.lhRemoveConstraints = listener(app.ConstraintType, 'RemoveConstraintsEvent', @(s,e)removeConstraints(wrefApp.Handle,s,e));

            % Listen to the ConstraintType class to update the Constraints class grid visibility
            app.lhUpdateConstraintsGrid = listener(app.ConstraintType, 'UpdateConstraintsGridEvent', ...
                @(s,e)updateConstraintsGrid(wrefApp.Handle,s,e));

            % Listen to sub-views for users clicking the context sensitive help (Csh) image
            fun = @(x) listener(x, 'CshImageClickedEvent', @(s,e)goToDocLink(wrefApp.Handle,s,e));
            app.lhHelpClicked = arrayfun(fun, [app.SelectSolver, app.ObjectiveFunction, ...
                app.Constraints, app.Options]);
        end

        function createComponents(app)

            % LayoutManager (property defined in base class)
            app.LayoutManager.ColumnWidth = {'1x'};
            app.LayoutManager.RowHeight = {'fit'};

            % Need to place LayoutManager within the UberTaskGrid
            h = matlab.internal.editor.LiveTaskUtilities.getFigure(app);
            parentContainer = findall(h, 'Tag', 'UberTaskGrid', 'Type', 'uigridlayout');
            % This check handles cases where the task is launched independently
            % of the uber task (like testing)
            if ~isempty(parentContainer)
                app.LayoutManager.Parent = parentContainer;
                app.LayoutManager.Layout.Row = 3;
                app.LayoutManager.Layout.Column = 1;
                app.LayoutManager.Padding = [0, 0, 0, 0];
            end

            % Accordion
            app.UIAccordion = matlab.ui.container.internal.Accordion('Parent', app.LayoutManager);

            % ProblemType accordion panel
            app.ProblemTypeAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', app.UIAccordion);
            app.ProblemTypeAccordionPanel.Title = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'ProblemType');

            % ProblemTypeGrid
            app.ProblemTypeGrid = uigridlayout(app.ProblemTypeAccordionPanel);
            app.ProblemTypeGrid.RowHeight = {'fit', 'fit', 'fit'};
            app.ProblemTypeGrid.ColumnWidth = {'fit', 'fit'};

            % Problem data accordion panel
            app.ProblemDataAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', app.UIAccordion);
            app.ProblemDataAccordionPanel.Title = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'ProblemData');

            % ProblemDataGrid
            app.ProblemDataGrid = uigridlayout(app.ProblemDataAccordionPanel);
            app.ProblemDataGrid.RowHeight = {'fit', 'fit', 'fit'};
            app.ProblemDataGrid.ColumnWidth = {'fit', 'fit'};

            % SolverOptions Accordion Panel
            app.SolverOptionsAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', app.UIAccordion);
            app.SolverOptionsAccordionPanel.Title = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'SolverOptions');
            app.SolverOptionsAccordionPanel.Collapsed = true;

            % Display Accordion Panel
            app.DisplayAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', app.UIAccordion);
            app.DisplayAccordionPanel.Title = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'DisplayProgress');
            app.DisplayAccordionPanel.Collapsed = false;

            % DisplayGrid
            app.DisplayGrid = uigridlayout(app.DisplayAccordionPanel);
            app.DisplayGrid.ColumnWidth = {'fit', 'fit'};
            app.DisplayGrid.RowHeight = {'fit', 'fit'};

            % Create sub-view objects. Pass in the view's parent container
            app.ObjectiveType = matlab.internal.optimgui.optimize.solverbased.views.ObjectiveType(...
                app.ProblemTypeGrid);
            app.ConstraintType = matlab.internal.optimgui.optimize.solverbased.views.ConstraintType(...
                app.ProblemTypeGrid);
            app.SelectSolver = matlab.internal.optimgui.optimize.solverbased.views.SelectSolver(...
                app.ProblemTypeGrid);
            app.ObjectiveFunction = matlab.internal.optimgui.optimize.solverbased.views.ObjectiveFunction(...
                app.ProblemDataGrid);
            app.Solver = matlab.internal.optimgui.optimize.solverbased.views.Solver(...
                app.ProblemDataGrid);
            app.Constraints = matlab.internal.optimgui.optimize.solverbased.views.Constraints(...
                app.ProblemDataGrid);
            app.Options = matlab.internal.optimgui.optimize.solverbased.views.Options(...
                app.SolverOptionsAccordionPanel);
            app.TextDisplay = matlab.internal.optimgui.optimize.solverbased.views.TextDisplay(...
                app.DisplayGrid);
            app.PlotFcn = matlab.internal.optimgui.optimize.solverbased.views.PlotFcn(...
                app.DisplayGrid);
        end

        function updateView(app)

            % Called by the setState method on undo/redo and when loading a saved
            % script with a task.

            % Update all sub-views
            app.ObjectiveType.updateView(app.Model);
            app.ConstraintType.updateView(app.Model);
            app.SelectSolver.updateView(app.Model);
            app.updateSolverModelViews();

            % Update the Enable property of solver model related views as necessary
            app.updateSolverModelViewsEnabled();

            % Listener callbacks are not triggered by setState. Explicitly call
            % ProblemTypeChanged to sync the problem type icons with the model
            app.ProblemTypeChanged();
        end

        function updateSolverModelViews(app)

            % Called by updateView and SolverNameChanged methods.
            % Updates all solver model related views

            app.ObjectiveFunction.updateView(app.Model.SolverModel);
            app.Solver.updateView(app.Model.SolverModel);
            app.Constraints.updateView(app.Model.SolverModel);
            app.Options.updateView(app.Model.SolverModel.Options);
            app.TextDisplay.updateView(app.Model.SolverModel.Options);
            app.PlotFcn.updateView(app.Model.SolverModel.Options);
        end

        function SolverListChanged(app, ~, ~)

            % Listener callback for changes to Model.SolverList property

            % Update SelectSolver.DropDown ItemsData and Items properties
            app.SelectSolver.DropDown.ItemsData = app.Model.SolverList;
            app.SelectSolver.DropDown.Items = app.Model.SolverListMessage;

            % If the current solver is not part of the new SolverList,
            % update Model.SolverName
            if ~any(strcmp(app.Model.SolverList, app.Model.SolverName))
                app.Model.SolverName = app.Model.SolverList{1};
            end

            % Update SelectSolver.DropDown.Value property
            app.SelectSolver.DropDown.Value = app.Model.SolverName;
        end

        function SolverNameChanged(app, ~, ~)

            % Listener callback for changes to Model.SolverName property

            % Set new Model.SolverModel property
            app.Model.updateSolverModel();

            % Update the Enable property of solver model related views as necessary
            app.updateSolverModelViewsEnabled();

            % If the user has a license for the specified problem type,
            % Update solver model related views
            if app.Model.hasLicense
                app.updateSolverModelViews();
            end
        end

        function ProblemTypeChanged(app, ~, ~)

            % Listener callback for changes to problem type buttons and called by updateView method.

            % Start with all objective and constraint types enabled
            objectiveEnable = repmat({'on'}, size(app.ObjectiveType.StateButtons));
            constraintEnable = repmat({'on'}, size(app.ConstraintType.StateButtons));

            % Linear objective and Unconstrained cannot co-exist
            if strcmp(app.Model.ObjectiveType, 'Linear')
                constraintEnable(strcmp({app.ConstraintType.StateButtons.Tag}, 'None')) = {'off'};
            elseif strcmp(app.Model.ConstraintType, 'None')
                objectiveEnable(strcmp({app.ObjectiveType.StateButtons.Tag}, 'Linear')) = {'off'};
            end

            % Set Enable property of buttons
            [app.ObjectiveType.StateButtons.Enable] = deal(objectiveEnable{:});
            [app.ConstraintType.StateButtons.Enable] = deal(constraintEnable{:});

            % Update figure
            drawnow nocallbacks
        end

        function ConstraintTypeChanged(app, ~, ~)

            % Listener callback for changes to ConstraintType. Selected constraints
            % may limit valid Algorithms
            app.Options.updateAlgorithmSelections();
        end

        function removeConstraints(app, ~, event)

            % Listener callback for the RemoveConstraintsEvent of the
            % ConstraintType class.

            % Reset any removed constraints back to their default value
            app.Constraints.resetConstraints(event.Data);
        end

        function updateConstraintsGrid(app, ~, event)

            % Listener callback for the UpdateConstraintsGridEvent of the
            % ConstraintType class.

            % If necessary, create the selected constraint widget
            thisConstraint = event.Data;
            if any(strcmp(thisConstraint, app.Model.SolverModel.Constraints)) && ...
                    isempty(app.Constraints.(thisConstraint))
                app.Constraints.makeConstraintWidget(thisConstraint);
            end

            % Update the constraints view grid visibility
            app.Constraints.updateGridVisibility();
        end

        function updateSolverModelViewsEnabled(app)

            % Called by updateView and SolverNameChanged methods. Aligns the Enable property
            % of solver model view components with the Model.hasLicense property

            % If no solver is available due to the license, disable solver model views.
            % Else, enable views, but only if already disabled
            if ~app.Model.hasLicense
                app.setSolverModelViewsEnabled('off');
            elseif ~app.areSolverModelViewsEnabled
                app.setSolverModelViewsEnabled('on');
            end
        end

        function setSolverModelViewsEnabled(app, value)

            % Called by updateSolverModelViewsEnabled

            % Set Enable property of all components of the solver model related views accordingly
            set(findall([app.ProblemDataAccordionPanel, app.SolverOptionsAccordionPanel, ...
                app.DisplayAccordionPanel], '-property', 'Enable'), 'Enable', value);
            app.areSolverModelViewsEnabled = strcmp(value, 'on');
        end

        function setStateFromStruct(app, state)

            % If the SolverName contains unlicensed, re-check the SolverName based on the
            % objective and constraint types. The user may have saved the task in some
            % license state, but it could be different when they re-open it.
            % Elseif the SolverName is not valid for the current license throw an error
            % and don't load the task
            if contains(state.SolverName, 'unlicensed')
                solverList = app.Model.SolverTypeMap(state.ObjectiveType, ...
                    state.ConstraintType);
                state.SolverName = solverList{1};
            elseif ~any(strcmp(state.SolverName, app.Model.SolverTypeMap.masterList))
                globalSolvers = app.Model.SolverTypeMap.globalSolvers;
                if any(strcmp(state.SolverName, globalSolvers(:, 1)))
                    license_status = app.Model.SolverTypeMap.UnlicensedGlobal;
                else
                    license_status = app.Model.SolverTypeMap.UnlicensedOptim;
                end
                error(['matlab:internal:optimfun:optimgui:', license_status{:}], ...
                    matlab.internal.optimgui.optimize.utils.getMessage('Labels', license_status{:}))
            end

            % Create OptimizeState object from state structure
            objState = app.Model.State.updateState(state);

            % Update model based on state object
            app.Model.updateModel(objState);

            % Update app view
            app.updateView();
        end
    end
end
