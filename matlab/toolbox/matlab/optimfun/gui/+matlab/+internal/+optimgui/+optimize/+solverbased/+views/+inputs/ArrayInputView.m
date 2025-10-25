classdef ArrayInputView < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage
    % Manage the front-end of array inputs for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % WorkspaceDropDown component to specify the array value
        Input (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown
    end

    methods (Access = public)

        function this = ArrayInputView(varargin)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(...
                varargin{:});
        end

        function updateView(this, model)

            % Call superclass method
            updateView@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(...
                this, model);

            % Set view components from model
            this.Input.FilterVariablesFcn = this.Model.WidgetProperties.FilterVariablesFcn;
            this.Input.Tooltip = this.Model.WidgetProperties.Tooltip;
            matlab.internal.optimgui.optimize.utils.updateWorkspaceDropDownValue(...
                this.Input, this.Model.Value);
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(this);

            % Input
            this.Input = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', this.Grid);
            this.Input.Layout.Row = 1;
            this.Input.Layout.Column = 1;
            this.Input.ValueChangedFcn = @this.inputChanged;
            this.Input.Tag = this.Tag;
        end

        function inputChanged(this, src, ~)

            % Update model
            this.Model.Value = src.Value;

            % Call valueChanged() method
            this.valueChanged();
        end
    end
end
