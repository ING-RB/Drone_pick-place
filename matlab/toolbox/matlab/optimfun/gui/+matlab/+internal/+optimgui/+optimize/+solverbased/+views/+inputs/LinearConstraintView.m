classdef LinearConstraintView < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView
    % Manage the front-end of a linear constraint input for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Input controls
        LHSLabel (1, 1) matlab.ui.control.Label
        LHSInput (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown
        RelationLabel (1, 1) matlab.ui.control.Label
        RHSInput (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown
        RHSLabel (1, 1) matlab.ui.control.Label
    end

    methods (Access = public)

        function this = LinearConstraintView(parentContainer, tag)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView(...
                parentContainer, tag);
        end

        function updateView(this, model)

            % Update Model reference
            this.Model = model;

            % Set view components from model
            this.LHSLabel.Text = this.Model.WidgetProperties.LHSLabel;
            matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                this.LHSInput, this.Model.Value.LHS);
            this.RelationLabel.Text = this.Model.WidgetProperties.RelationLabel;
            this.RHSLabel.Text = this.Model.WidgetProperties.RHSLabel;
            matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                this.RHSInput, this.Model.Value.RHS);
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView(this);
            
            % Extend underlying grid
            this.Grid.ColumnWidth = repmat({'fit'}, 1, 5);

            % LHSLabel
            this.LHSLabel = uilabel(this.Grid);
            this.LHSLabel.Layout.Row = 1;
            this.LHSLabel.Layout.Column = 1;

            % LHSInput
            this.LHSInput = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.Grid);
            this.LHSInput.Layout.Row = 1;
            this.LHSInput.Layout.Column = 2;
            this.LHSInput.ValueChangedFcn = @this.inputChanged;
            this.LHSInput.FilterVariablesFcn = ...
                matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getMatrixFilter();
            this.LHSInput.Tooltip = ...
                matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'MatrixTooltip');
            this.LHSInput.Tag = [this.Tag, 'LHS'];
            this.LHSInput.UserData.ModelField = 'LHS';

            % RelationLabel
            this.RelationLabel = uilabel(this.Grid);
            this.RelationLabel.Layout.Row = 1;
            this.RelationLabel.Layout.Column = 3;
            this.RelationLabel.HorizontalAlignment = 'center';
            this.RelationLabel.FontWeight = 'bold';
            this.RelationLabel.Interpreter = 'latex';

            % RHSLabel
            this.RHSLabel = uilabel(this.Grid);
            this.RHSLabel.Layout.Row = 1;
            this.RHSLabel.Layout.Column = 4;

            % RHSInput
            this.RHSInput = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.Grid);
            this.RHSInput.Layout.Row = 1;
            this.RHSInput.Layout.Column = 5;
            this.RHSInput.ValueChangedFcn = @this.inputChanged;
            this.RHSInput.FilterVariablesFcn = ...
                matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getVectorFilter();
            this.RHSInput.Tooltip = ...
                matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'VectorTooltip');
            this.RHSInput.Tag = [this.Tag, 'RHS'];
            this.RHSInput.UserData.ModelField = 'RHS';
        end

        function inputChanged(this, src, ~)

            % Callback when user changes LHS or RHS input
            
            % Update model
            this.Model.Value.(src.UserData.ModelField) = src.Value;

            % Call valueChanged() method
            this.valueChanged();
        end
    end
end
