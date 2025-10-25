classdef AbstractMultiSourceInputView < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage
    % Manage the front-end of problem inputs for the solver-based Optimize LET
    % that can be "multi-sourced". For example, function inputs can be:
    % 1) from file, 2) local function, or 3) from workspace.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % DropDown component to specify the source of the view's input.
        % For BoundsView subclass, 'SpecifyBounds' or 'FromWorkspace'
        % For FunctionView subclass, 'FromFile', 'LocalFcn', or 'FcnHandle'
        SourceDropDown (1, 1) matlab.ui.control.DropDown
    end

    methods (Access = public)

        function this = AbstractMultiSourceInputView(varargin)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(...
                varargin{:});
        end

        function updateView(this, model)

            % Call superclass method
            updateView@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(...
                this, model);

            % Set SourceDropDown from model
            this.SourceDropDown.Value = this.Model.Value.Source;
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputViewWithMessage(this);

            % Extend underlying grid
            this.Grid.ColumnWidth = repmat({'fit'}, 1, 2);

            % SourceDropDown
            this.SourceDropDown = uidropdown(this.Grid);
            this.SourceDropDown.Layout.Row = 1;
            this.SourceDropDown.Layout.Column = 1;
            this.SourceDropDown.ValueChangedFcn = @this.sourceChanged;
            this.SourceDropDown.Tag = [this.Tag, 'Source'];
        end

        function sourceChanged(this, src, ~)

            % Update model source
            this.Model.Value.Source = src.Value;
        end
    end
end
