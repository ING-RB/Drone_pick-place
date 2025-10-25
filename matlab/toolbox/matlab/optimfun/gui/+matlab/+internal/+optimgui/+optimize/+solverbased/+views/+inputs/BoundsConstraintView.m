classdef BoundsConstraintView < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView
    % Manage the front-end of a bound constraint input for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Input controls
        SpecifyBoundsInput (1, 1) matlab.ui.control.NumericEditField
        FromWorkspaceInput (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown
        BoundsLabel (1, 1) matlab.ui.control.Label

        % Grid column widths depend on the Source. They show the relevant inputs
        SpecifyBoundsColumnWidth = {'fit', 'fit', 0, 'fit'};
        FromWorkspaceColumnWidth = {'fit', 0, 'fit', 'fit'};
    end

    methods (Access = public)

        function this = BoundsConstraintView(parentContainer, tag)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                parentContainer, tag);
        end

        function updateView(this, model)

            % Call superclass method
            updateView@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                this, model);

            % Set FromWorkspaceInput FilterVariablesFcn and Tooltip
            this.FromWorkspaceInput.FilterVariablesFcn = this.Model.WidgetProperties.FilterVariablesFcn;
            this.FromWorkspaceInput.Tooltip = this.Model.WidgetProperties.Tooltip;
            
            % Setting the input depends on the source
            if strcmp(this.Model.Value.Source, 'SpecifyBounds')
                % If the Source is specify, convert value to double for
                % numeric edit field
                this.SpecifyBoundsInput.Value = str2double(this.Model.Value.Bounds);
            else % FromWorkspace
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FromWorkspaceInput, this.Model.Value.Bounds);
            end

            % Set relation label
            this.BoundsLabel.Text = this.Model.WidgetProperties.BoundsLabel;

            % Set Grid column Width
            this.Grid.ColumnWidth = this.([this.Model.Value.Source, 'ColumnWidth']);
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(this);

            % Extend underlying grid
            this.Grid.ColumnWidth = this.SpecifyBoundsColumnWidth;

            % Extend SourceDropDown with relevant items
            this.SourceDropDown.ItemsData = {'SpecifyBounds', 'FromWorkspace'};
            this.SourceDropDown.Items = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', this.SourceDropDown.ItemsData);
            this.SourceDropDown.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
                'Tooltips', 'boundsSource');

            % SpecifyBoundsInput
            this.SpecifyBoundsInput = uieditfield(this.Grid, 'numeric');
            this.SpecifyBoundsInput.Layout.Row = 1;
            this.SpecifyBoundsInput.Layout.Column = 2;
            this.SpecifyBoundsInput.ValueChangedFcn = @this.inputChanged;
            this.SpecifyBoundsInput.HorizontalAlignment = 'left';
            this.SpecifyBoundsInput.Tag = [this.Tag, 'SpecifyBounds'];
            this.SpecifyBoundsInput.UserData.ConvertToChar = true;

            % FromWorkspaceInput
            this.FromWorkspaceInput = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.Grid);
            this.FromWorkspaceInput.Layout.Row = 1;
            this.FromWorkspaceInput.Layout.Column = 3;
            this.FromWorkspaceInput.ValueChangedFcn = @this.inputChanged;
            this.FromWorkspaceInput.FilterVariablesFcn = ...
                matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getArrayFilter();
            this.FromWorkspaceInput.Tag = [this.Tag, 'FromWorkspace'];
            this.FromWorkspaceInput.UserData.ConvertToChar = false;

            % BoundsLabel
            this.BoundsLabel = uilabel(this.Grid);
            this.BoundsLabel.Layout.Row = 1;
            this.BoundsLabel.Layout.Column = 4;
            this.BoundsLabel.HorizontalAlignment = 'center';
            this.BoundsLabel.FontWeight = 'bold';
            this.BoundsLabel.Interpreter = 'latex';
            this.BoundsLabel.Text = '';
        end

        function sourceChanged(this, src, event)

            % Call superclass method
            sourceChanged@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractMultiSourceInputView(...
                this, src, event);

            % Reset newly selected source to its default value
            if strcmp(this.Model.Value.Source, 'SpecifyBounds')
                this.Model.Value.Bounds = this.Model.DefaultValue.Bounds;
                this.SpecifyBoundsInput.Value = str2double(this.Model.Value.Bounds);
            else % FromWorkspace
                this.Model.Value.Bounds = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
                matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                    this.FromWorkspaceInput, this.Model.Value.Bounds);
            end

            % Set Grid column width
            this.Grid.ColumnWidth = this.([this.Model.Value.Source, 'ColumnWidth']);

            % Call valueChanged() method implemented in superclass
            this.valueChanged();
        end

        function inputChanged(this, src, ~)

            % Callback when user changes either the Specify or FromWorkspace input

            % Check to convert input value to char
            if src.UserData.ConvertToChar
                val = num2str(src.Value);
            else
                val = src.Value;
            end

            % Update model
            this.Model.Value.Bounds = val;

            % Call valueChanged() method
            this.valueChanged();
        end
    end
end
