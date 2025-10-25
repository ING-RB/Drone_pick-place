classdef AbstractInputViewWithMessage < matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView
    % Manage the front-end of problem inputs for the solver-based Optimize LET
    % that can be hidden with messages. In some special cases, we may want to
    % hide the input components and instead show a message. For example, this
    % is used by the surrogateopt solver class when the user adds a nonlinear
    % constraint fcn. Instead of showing the fcn input components, a message
    % tells the user to specify the nonlinear constraint in the objective fcn.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Create a wrapper grid around the Grid property (defined in superclass)
        % and the message. This will make hiding/viewing the inputs and message easy.
        WrapperGrid (1, 1) matlab.ui.container.GridLayout

        % Message to show instead of the input components
        Message (1, 1) matlab.ui.control.Label
    end

    methods (Access = public)

        function this = AbstractInputViewWithMessage(varargin)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView(...
                varargin{:});
        end

        function updateView(this, model)

            % Update Model reference
            this.Model = model;

            % Set underlying message object
            this.Message.Text = this.Model.WidgetProperties.Message;

            % Visibility of inputs and message depend on whether there is a message
            if isempty(this.Message.Text)
                this.WrapperGrid.ColumnWidth = {'fit', 0};
            else
                this.WrapperGrid.ColumnWidth = {0, 'fit'};
            end
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Call superclass method
            createComponents@matlab.internal.optimgui.optimize.solverbased.views.inputs.AbstractInputView(this);

            % WrapperGrid
            this.WrapperGrid = uigridlayout(this.ParentContainer);
            this.WrapperGrid.Layout.Row = 1;
            this.WrapperGrid.Layout.Column = 1;
            this.WrapperGrid.RowHeight = {'fit'};
            this.WrapperGrid.ColumnWidth = {'fit', 'fit'};
            this.WrapperGrid.Padding = [0, 0, 0, 0];
            this.WrapperGrid.Tag = [this.Tag, 'WrapperGrid'];

            % Place Grid in WrapperGrid
            this.Grid.Parent = this.WrapperGrid;
            this.Grid.Layout.Row = 1;
            this.Grid.Layout.Column = 1;

            % Message
            this.Message = uilabel(this.WrapperGrid);
            this.Message.Layout.Row = 1;
            this.Message.Layout.Column = 2;
            this.Message.Text = '';
            this.Message.Tag = [this.Tag, 'Message'];
        end
    end
end
