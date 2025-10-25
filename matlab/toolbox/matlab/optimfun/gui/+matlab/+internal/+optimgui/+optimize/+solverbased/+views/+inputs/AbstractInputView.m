classdef AbstractInputView < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % Manage the front-end of problem inputs for the solver-based Optimize LET
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Main grid to hold underlying graphics objects for the component
        Grid (1, 1) matlab.ui.container.GridLayout
    end

    methods (Access = public)

        function this = AbstractInputView(varargin)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
                varargin{:});
        end
    end

    methods (Access = protected)

        function createComponents(this)

            % Set default grid properties
            this.Grid = uigridlayout(this.ParentContainer);
            this.Grid.Layout.Row = 1;
            this.Grid.Layout.Column = 1;
            this.Grid.RowHeight = {'fit'};
            this.Grid.ColumnWidth = {'fit'};
            this.Grid.Padding = [0, 0, 0, 0];
        end
    end
end
