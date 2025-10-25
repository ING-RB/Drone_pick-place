classdef ScrollableGridBagLayout < matlabshared.application.layout.GridBagLayout

    properties (SetAccess = protected, Hidden)
        ViewPanel;
        ScrollablePanel;
        VerticalScrollbar;
        HorizontalScrollbar;
    end

    properties (Access = protected)
        ScrollListener;
        ScrollablePosition
    end

    methods
        function this = ScrollableGridBagLayout(hPanel, varargin)
            this@matlabshared.application.layout.GridBagLayout(hPanel, varargin{:});

            hPanel.SizeChangedFcn = @this.resizeMainPanel;

            % The ViewPanel limits the amount of viewable area of the
            % scroll panel.
            parentTag = hPanel.Tag;
            this.ViewPanel = uipanel(hPanel, ...
                'Units',      'pixels', ...
                'Tag',        ['ViewPanel','_',parentTag], ...
                'BorderType', 'none', ...
                'AutoResizeChildren', 'off', ...
                'SizeChangedFcn', @this.resizeViewPanel);

            % Everything added to the layout is moved to the scrollable
            % panel.  This panel is moved when the sliders are moved
            this.ScrollablePanel = uipanel(this.ViewPanel, ...
                'Units',      'pixels', ...
                'Tag',        ['ScrollablePanel','_',parentTag], ...
                'BorderType', 'none', ...
                'AutoResizeChildren', 'off', ...
                'SizeChangedFcn', @this.resizeScrollablePanel);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(this.ScrollablePanel, ...
                'BackgroundColor', '--mw-backgroundColor-primary');
        end

        function add(this, h, varargin)

            if nargin > 2
                [varargin{:}] = convertStringsToChars(varargin{:});
            end

            add@matlabshared.application.layout.GridBagLayout(this, h, varargin{:});

            % Move everything to the hidden scrollable panel.
            set(h, 'Parent', this.ScrollablePanel);
        end

        function remove(this, h, varargin)
            if nargin == 2
                set(h, 'Parent', this.Panel);
            else
                set(this.Grid(h, varargin{1}), 'Parent', this.Panel);
            end
            remove@matlabshared.application.layout.GridBagLayout(this, h, varargin{:});
        end

        function delete(this)

            % If this is being deleted while the panel still exists, move
            % everything back to the panel.  Do not let the widgets be
            % destroyed.
            p = this.Panel;
            if ishghandle(p)
                grid = this.Grid;
                grid = grid(:);
                grid(isnan(grid)) = [];
                set(grid, 'Parent', p);
            end

            % Delete all the objects owned by the manager.  ScrollablePanel
            % will get cleaned up when ViewPanel is deleted.
            delete(this.ViewPanel);
            if this.VerticalScrollbar ~= -1
                delete(this.VerticalScrollbar);
            end
            if this.HorizontalScrollbar ~= -1
                delete(this.HorizontalScrollbar);
            end
        end
    end

    methods (Access = protected)
        function updateForNewConstraints(this, varargin)
            resizeMainPanel(this);
            resizeViewPanel(this);
            resizeScrollablePanel(this);
            update(this, 'force');
        end

        function [viewPanelPos, scrollablePos] = computeNewPanelSizes(this)

            [width, height] = getMinimumSize(this);

            vGap = this.VerticalGap;
            hGap = this.HorizontalGap;

            panel = this.Panel;

            bw = 0;
            if ishghandle(panel, 'uipanel') && ~strcmp(panel.BorderType, 'none')
                bw = panel.BorderWidth;
            end

            % The view panel is the same size as the figure/panel the
            % layout is managing.
            viewPanelPos = getpixelposition(panel);
            viewPanelPos(1:2) = [1 1] + bw;
            viewPanelPos(3:4) = viewPanelPos(3:4) - 3 * bw;

            sliderWidth = 9;

            % If the minimum width/height is greater than the size of the
            % view, then the slider must be shown.
            showVerticalScrollbar = viewPanelPos(4) < height - vGap;
            showHorizontalScrollbar = viewPanelPos(3) < width  - hGap;

            if showVerticalScrollbar
                viewPanelPos(3) = viewPanelPos(3) - sliderWidth;
            end
            if showHorizontalScrollbar
                viewPanelPos(4) = viewPanelPos(4) - sliderWidth;
                viewPanelPos(2) = sliderWidth + 1;
            end

            scrollablePos = [1 1 viewPanelPos(3:4)];

            yScroll = this.VerticalScrollbar;
            if showVerticalScrollbar

                scrollablePos(4) = height;

                % Create a listener to handle the scroll wheel when over
                % this figure.
                this.ScrollListener = event.listener(ancestor(panel, 'figure'), ...
                    'WindowScrollWheel', @this.scrollWheelCallback);
                yMax = height - viewPanelPos(4);
                pos = [viewPanelPos(3)+1 1 sliderWidth viewPanelPos(4)];
                if showHorizontalScrollbar
                    pos(2) = sliderWidth + 1;
                end

                % Create the y slider only when it is needed
                if isempty(yScroll)
                    yScroll = matlabshared.application.Scrollbar(panel, ...
                        'Tag', 'VerticalScrollbar', ...
                        'Value', yMax);
                    addlistener(yScroll, 'ValueChanged', @this.yScrollbarCallback);
                    this.VerticalScrollbar = yScroll;
                end

                % Configure the VerticalScrollbar based on the dimensions of the
                % viewport and the minimum height of all the widgets
                value = yScroll.Value;
                if value > yMax
                    value = yMax;
                else

                    % Because the positioning is inverted, we need to
                    % compensate when changing the layout to avoid weird
                    % positioning.
                    value = yMax - (yScroll.Maximum - yScroll.Value);
                end
                scrollablePos(2) = 1 - value;
                configure(yScroll, [], yMax, value, viewPanelPos(4) / height);
                yScroll.Position = pos;
                yScroll.Visible  = 'on';
                yScroll.Value = value;
            elseif ~isempty(yScroll)
                yScroll.Visible = 'off';
                this.ScrollListener = [];
            end

            xScroll = this.HorizontalScrollbar;
            if showHorizontalScrollbar
                scrollablePos(3) = width;
                if isempty(xScroll)
                    xScroll = matlabshared.application.Scrollbar(panel, ...
                        'Tag', 'HorizontalScrollbar');
                    addlistener(xScroll, 'ValueChanged', @this.xScrollbarCallback);
                    this.HorizontalScrollbar = xScroll;
                end
                % Configure the HorizontalScrollbar based on the dimensions of the
                % viewport and the minimum width of all the widgets
                xMax = width - viewPanelPos(3) + 1;
                value = xScroll.Value;
                if value > xMax
                    value = xMax;
                end
                configure(xScroll, [], xMax, value, viewPanelPos(3) / width);
                xScroll.Visible = 'on';
                xScroll.Position = [1 1 viewPanelPos(3) sliderWidth];
                xScroll.Value = 1;
            elseif ~isempty(xScroll)
                xScroll.Visible = 'off';
            end

            scrollablePos(find(scrollablePos(3:4) <= 0) + 2) = 1;
            viewPanelPos(find(viewPanelPos(3:4) <= 0) + 2) = 1;
        end

        function resizeMainPanel(this,~,~)
            [viewPanelPos, this.ScrollablePosition] = computeNewPanelSizes(this);
            set(this.ViewPanel, 'Position', viewPanelPos);
        end

        function resizeViewPanel(this,~,~)
            pos = this.ScrollablePosition;
            if ~isempty(pos)
                set(this.ScrollablePanel, 'Position', pos);
            end
        end

        function resizeScrollablePanel(this,~,~)
            % Allow the gridbag to layout all the children in the grid.
            layout(this);
        end

        % Overload to get the full scrollable panel size even though it
        % cannot be entirely seen.
        function pos = getPanelPosition(this)
            pos = get(this.ScrollablePanel, 'Position');
        end

        function yScrollbarCallback(this, ~, ~)
            scrollablePos = get(this.ScrollablePanel, 'Position');
            scrollablePos(2) = 1 - this.VerticalScrollbar.Value;
            set(this.ScrollablePanel, 'Position', scrollablePos);
        end

        function xScrollbarCallback(this, ~, ~)
            scrollablePos = get(this.ScrollablePanel, 'Position');

            scrollablePos(1) = 1 - this.HorizontalScrollbar.Value;
            set(this.ScrollablePanel, 'Position', scrollablePos);
        end

        function scrollWheelCallback(this, ~, ev)

            % If the mouse is not over the figure being managed then return
            % early as the scroll should have no effect.
            if ~isMouseOverPanel(this)
                return
            end
            slider = this.VerticalScrollbar;
            max    = slider.Maximum;
            min    = slider.Minimum;
            value  = slider.Value;
            value  = value - ev.VerticalScrollCount * ev.VerticalScrollAmount * 3;
            if value > max
                value = max;
            elseif value < min
                value = min;
            end
            slider.Value = value;
            yScrollbarCallback(this);
        end

        function b = isMouseOverPanel(this)
            p = this.Panel;
            if ishghandle(p, 'figure')
                b = true;
                return;
            end

            pos = getPositionRelativeToFigure(p);
            pt  = get(ancestor(p, 'figure'), 'CurrentPoint');

            b = pt(1) > pos(1) && pt(1) < pos(1) + pos(3) && ...
                pt(2) > pos(2) && pt(2) < pos(2) + pos(4);
        end
    end
end

function pos = getPositionRelativeToFigure(obj)

pos = getpixelposition(obj);
parent = get(obj, 'Parent');

% Loop until we hit the figure.
while ~strcmp(get(parent, 'type'), 'figure')
    parentPos = getpixelposition(parent);

    % Add the pixel position of the parent to the pixel position of the
    % object.  Remove [1 1] because in pixels [1 1] is the origin.
    pos(1) = pos(1)+parentPos(1)-1;
    pos(2) = pos(2)+parentPos(2)-1;

    parent = get(parent, 'Parent');
end

end

% [EOF]