classdef FunctionView < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView
    % Manage the front-end of a function input for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Grid for everything BUT FcnArgsView
        InputsGrid (1, 1) matlab.ui.container.GridLayout

        % Grid for FcnArgsView
        FcnArgsGrid (1, 1) matlab.ui.container.GridLayout

        % Input controls
        FromFileInput % (1, 1) matlab.internal.optimgui.optimize.widgets.FcnFileComponent
        LocalFcnInput % (1, 1) matlab.internal.optimgui.optimize.widgets.LocalFcnComponent
        FcnTemplateButton (1, 1) matlab.ui.control.Button
        FcnHandleInput (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown
        FcnArgsView matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionArgsView

        % Grid column widths depend on the Source. They show the relevant inputs
        FromFileColumnWidth = {'fit', 'fit', 0, 'fit', 0};
        LocalFcnColumnWidth = {'fit', 0, 'fit', 'fit', 0};
        FcnHandleColumnWidth = {'fit', 0, 0, 0, 'fit'};

        % Default values for re-setting when source changes
        DefaultFromFile = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn;
        DefaultLocalFcn = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        DefaultFcnHandle = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;

        % Listen for changes to FcnArgsView
        lhFcnArgsChanged event.listener
    end

    methods (Access = public)

        function this = FunctionView(parentContainer, tag)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                parentContainer, tag);

            % Listen for changes to FcnArgsView
            wrefThis = matlab.lang.WeakReference(this);
            this.lhFcnArgsChanged = listener(this.FcnArgsView, ...
                'ValueChangedEvent', @(s,e)valueChanged(wrefThis.Handle,s,e));
        end

        function updateView(this, model)

            % Call superclass method
            updateView@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                this, model);

            % Set FcnHandleInput FilterVariablesFcn and Tooltip
            this.FcnHandleInput.FilterVariablesFcn = this.Model.WidgetProperties.FilterVariablesFcn;
            this.FcnHandleInput.Tooltip = this.Model.WidgetProperties.Tooltip;
            
            % Setting the rest of the view depends on the source
            if strcmp(this.Model.Value.Source, 'FcnHandle')
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FcnHandleInput, this.Model.Value.Name);
                this.FcnArgsView.setParentGridRowAndHeight(0);
            else
                this.([this.Model.Value.Source, 'Input']).Value = this.Model.Value.Name;
                this.FcnArgsView.updateView(this.Model);
            end

            % Set InputsGrid column Width
            this.InputsGrid.ColumnWidth = this.([this.Model.Value.Source, 'ColumnWidth']);
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(this);

            % Extend Grid
            this.Grid.RowHeight = {'fit', 'fit'};
            
            % InputsGrid
            this.InputsGrid = uigridlayout(this.Grid);
            this.InputsGrid.Layout.Row = 1;
            this.InputsGrid.Layout.Column = 1;
            this.InputsGrid.RowHeight = {'fit', 'fit'};
            this.InputsGrid.ColumnWidth = this.FromFileColumnWidth;
            this.InputsGrid.Padding = [0, 0, 0, 0];

            % FcnArgsGrid
            this.FcnArgsGrid = uigridlayout(this.Grid);
            this.FcnArgsGrid.Layout.Row = 2;
            this.FcnArgsGrid.Layout.Column = 1;
            this.FcnArgsGrid.RowHeight = {'fit'};
            this.FcnArgsGrid.ColumnWidth = {'fit'};
            this.FcnArgsGrid.Padding = [0, 0, 0, 0];
            this.FcnArgsGrid.Tag = [this.Tag, 'FcnArgsGrid'];

            % Re-parent SourceDropDown and extend with relevant items
            this.SourceDropDown.Parent = this.InputsGrid;
            this.SourceDropDown.Layout.Row = 1;
            this.SourceDropDown.Layout.Column = 1;
            this.SourceDropDown.ItemsData = {'FromFile', 'LocalFcn', 'FcnHandle'};
            this.SourceDropDown.Items = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', this.SourceDropDown.ItemsData);
            this.SourceDropDown.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Tooltips', 'fcnSource');

            % FromFileInput
            this.FromFileInput = matlab.internal.optimgui.optimize.widgets.FcnFileComponent(this.InputsGrid);
            this.FromFileInput.Layout.Row = 1;
            this.FromFileInput.Layout.Column = 2;
            this.FromFileInput.ValueChangedFcn = @this.inputChanged;
            this.FromFileInput.Tag = [this.Tag, 'FromFile'];
            this.FromFileInput.UserData.ModelPropertyName = 'FcnName';
            this.FromFileInput.UserData.ValueChangedFcn = 'fcnChanged';
            this.FromFileInput.UserData.FcnType = 'file';

            % LocalFcnInput
            this.LocalFcnInput = matlab.internal.optimgui.optimize.widgets.LocalFcnComponent(this.InputsGrid);
            this.LocalFcnInput.Layout.Row = 1;
            this.LocalFcnInput.Layout.Column = 3;
            this.LocalFcnInput.ValueChangedFcn = @this.inputChanged;
            this.LocalFcnInput.Tag = [this.Tag, 'LocalFcn'];
            this.LocalFcnInput.UserData.ModelPropertyName = 'FcnName';
            this.LocalFcnInput.UserData.ValueChangedFcn = 'fcnChanged';
            this.LocalFcnInput.UserData.FcnType = 'local';

            % FcnTemplateButton
            this.FcnTemplateButton = uibutton(this.InputsGrid);
            this.FcnTemplateButton.Layout.Row = 1;
            this.FcnTemplateButton.Layout.Column = 4;
            this.FcnTemplateButton.ButtonPushedFcn = @this.createTemplate;
            this.FcnTemplateButton.Text = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'FcnTemplateButton');
            this.FcnTemplateButton.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'fcnTemplate');
            matlab.ui.control.internal.specifyIconID(this.FcnTemplateButton, "new", 16, 16);
            this.FcnTemplateButton.Tag = [this.Tag, 'Template'];

            % FcnHandleInput
            this.FcnHandleInput = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.InputsGrid);
            this.FcnHandleInput.Layout.Row = 1;
            this.FcnHandleInput.Layout.Column = 5;
            this.FcnHandleInput.ValueChangedFcn = @this.inputChanged;
            this.FcnHandleInput.FilterVariablesFcn = ...
                matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getFunctionFilter();
            this.FcnHandleInput.Tag = [this.Tag, 'FromWorkspace'];

            % FcnArgsView
            this.FcnArgsView = matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionArgsView(...
                this.FcnArgsGrid, this.Tag);
        end

        function sourceChanged(this, src, event)

            % Call superclass method
            sourceChanged@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                this, src, event);

            % Reset newly selected source to its default value
            value = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultFcnParse;
            value.Source = this.Model.Value.Source;
            value.Name = this.(['Default', this.Model.Value.Source]);
            this.Model.Value = value;
            if strcmp(this.Model.Value.Source, 'FcnHandle')
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FcnHandleInput, this.Model.Value.Name);
                this.FcnArgsView.setParentGridRowAndHeight(0);
            else % FcnFile or LocalFcn
                this.([this.Model.Value.Source, 'Input']).Value = this.Model.Value.Name;
                this.FcnArgsView.updateView(this.Model);
            end

            % Set Grid column width
            this.InputsGrid.ColumnWidth = this.([this.Model.Value.Source, 'ColumnWidth']);

            % Call valueChanged() method
            this.valueChanged();
        end

        function inputChanged(this, src, event)

            % Callback when user changes the FromFile, LocalFcn, or FcnHandle input

            % Update model
            this.Model.Value.Name = src.Value;

            % Extra processing if a function input
            if ~strcmp(this.Model.Value.Source, 'FcnHandle')

                % Is the default, empty value selected?
                if strcmp(src.Value, this.(['Default', this.Model.Value.Source]))

                    % Reset fcn inputs fields
                    this.resetFcnArgs();
                else
                    % Parse file inputs
                    this.parseFcn(src, event);
                end

                % Update fcn args view
                this.FcnArgsView.updateView(this.Model);
            end

            % Call valueChanged() method
            this.valueChanged();
        end

        function parseFcn(this, src, event)

            % Unpack input arguments
            fcnName = event.Data.FcnName;
            type = src.UserData.FcnType;

            % Parse fcn inputs
            args = matlab.internal.optimgui.optimize.utils.getArgs(fcnName, type);

            % If the fcn has fixed inputs, set fcn inputs fields
            % Else, reset
            if numel(args) > 1

                % Set fcn inputs fields
                this.Model.Value.VariableList = args;
                this.Model.Value.FreeVariable = args{1};
                fixedValues = repmat({matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue}, 1, numel(args) - 1);
                idx = min([numel(fixedValues), numel(this.Model.Value.FixedValues)]);
                fixedValues(1:idx) = this.Model.Value.FixedValues(1:idx);
                this.Model.Value.FixedValues = fixedValues;
            else

                % Reset fcn inputs fields
                this.resetFcnArgs();
            end
        end

        function resetFcnArgs(this)

            % Reset fcn inputs fields
            this.Model.Value.VariableList = {};
            this.Model.Value.FreeVariable = '';
            this.Model.Value.FixedValues = {};
        end

        function createTemplate(this, ~, ~)

            % Callback when the Create template button is clicked

            % Return template function text and function name
            [fcnText, fcnName] = matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput.getFcnTemplate(...
                this.Model.WidgetProperties.TemplateType);

            % Create template fcn
            this.([this.Model.Value.Source, 'Input']).createTemplate(fcnName, fcnText);
        end
    end
end
