classdef (Abstract) AbstractTaskViewWithHelp < matlab.internal.optimgui.optimize.views.AbstractTaskView
    % The AbstractViewWithHelp Abstract class defines common properties, methods, and
    % events for Optimize LET view classes that include context sensitive help.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Hidden, GetAccess = public, SetAccess = protected)

        % Context-sensitive-help (csh) image component that links to doc
        CshImage (1, :) matlab.ui.control.Image
    end

    events

        % Notify listeners when user clicks the help icon
        CshImageClickedEvent
    end

    methods (Access = public)

        function this = AbstractTaskViewWithHelp(varargin)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.views.AbstractTaskView(...
                varargin{:});
        end
    end

    methods (Access = protected)

        function createHelpIcon(this, parent, row, col, tooltip, tag)

            % Set properties with method input args
            this.CshImage = uiimage(parent);
            this.CshImage.Layout.Row = row;
            this.CshImage.Layout.Column = col;
            this.CshImage.Tooltip = tooltip;
            this.CshImage.Tag = tag;
            
            % Consistent properties
            this.CshImage.ImageClickedFcn = @this.cshImageClicked;
            matlab.ui.control.internal.specifyIconID(this.CshImage, "helpRecolorUI", 16, 16);
        end
    end

    methods (Abstract, Access = protected)

        % Callback when the user clicks the help icon
        cshImageClicked(this, src, event);
    end
end
