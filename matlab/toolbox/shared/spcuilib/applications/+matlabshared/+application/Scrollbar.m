classdef Scrollbar < matlab.mixin.SetGet
    %Scrollbar
    
    %   Copyright 2017 The MathWorks, Inc.
    
    properties (Dependent)
        Minimum;
        Maximum;
        Value;
        MajorStep;
        BackgroundColor;
        ForegroundColor;
        HighlightColor;
        Units;
        Position;
        Parent;
        Visible;
        Tag;
    end
    
    properties (Access = protected)
        Figure;
        Panel;
        Box;
        pMinimum = 0;
        pMaximum = 1;
        pValue   = 0;
        pMajorStep = 0.10;
        pForegroundColor = [0.7 0.7 0.7];
        OldPointer;
        MouseReleaseListener;
        MouseMotionListener;
        InitialPoint;
        InitialValue;
    end
    
    events
        ValueChanged
    end
    
    methods
        function this = Scrollbar(varargin)
            if nargin > 0 && ~ischar(varargin{1})
                hParent = varargin{1};
                varargin(1) = [];
            else
                parentIndex = find(strcmpi(varargin, 'Parent'));
                if isempty(parentIndex)
                    hParent = gcf;
                else
                    hParent = varargin{parentIndex + 1};
                end
                varargin(parentIndex:parentIndex + 1) = [];
            end
            fig = ancestor(hParent, 'figure');
            this.Figure = fig;
            
            % Create a panel for the background
            this.Panel = uipanel(hParent, ...
                'Units', 'Pixels', ...
                'Position', [20 20 60 20], ...
                'BackgroundColor', [.86 .86 .86], ...
                'Tag', 'Panel', ...
                'AutoResizeChildren', 'off', ...
                'ButtonDownFcn', @this.panelButtonDown, ...
                'Visible', 'on', ...
                'BorderType', 'none');
            
            % Create a second panel to represent the draggable area
            if matlabshared.application.usingWebFigures || matlab.ui.internal.isUIFigure(ancestor(hParent, 'figure'))
                boxProps = {};
            else
                boxProps = {'HighlightColor', [0.58 0.58 0.58]};
            end
            this.Box = uipanel(this.Panel, ...
                'Units', 'pixels', ...
                'Tag', 'Box', ...
                'BorderType', 'line', ...
                'BackgroundColor', this.pForegroundColor, ...
                boxProps{:}, ...
                'ButtonDownFcn', @this.boxButtonDown);
            
            % Set all the passed pv pairs
            if nargin
                set(this, varargin{:});
            end
            % Set the resize function here so it doesnt fire multiple times
            this.Panel.ResizeFcn = @this.resizeCallback;
            
            % Force a single layout at the end
            doLayout(this);
            
            motion  = event.listener(fig, 'WindowMouseMotion',  @this.onMouseMotion);
            release = event.listener(fig, 'WindowMouseRelease', @this.onMouseRelease);
            motion.Enabled  = false;
            release.Enabled = false;
            this.MouseMotionListener  = motion;
            this.MouseReleaseListener = release;
        end
        
        function delete(this)
            delete(this.Panel);
        end
        
        function configure(this, min, max, value, major)
            % Helper method to update all the important properties at once
            if nargin > 1
                if ~isempty(min)
                    this.pMinimum = min;
                end
                if nargin > 2
                    if ~isempty(max)
                        this.pMaximum = max;
                    end
                    if nargin > 3
                        if ~isempty(value)
                            this.pValue = value;
                        end
                        if nargin > 4
                            if ~isempty(major)
                                this.pMajorStep = major;
                            end
                        end
                    end
                end
                doLayout(this);
            end
        end
        
        function set.Minimum(this, min)
            this.pMinimum = min;
            if this.pValue < min
                this.pValue = min;
            end
            doLayout(this)
        end
        function min = get.Minimum(this)
            min = this.pMinimum;
        end
        
        function set.Maximum(this, max)
            this.pMaximum = max;
            if this.pValue > max
                this.pValue = max;
            end
            doLayout(this)
        end
        function max = get.Maximum(this)
            max = this.pMaximum;
        end
        
        function set.BackgroundColor(this, color)
            this.Panel.BackgroundColor = color;
        end
        function color = get.BackgroundColor(this)
            color = this.Panel.BackgroundColor;
        end
        
        function set.ForegroundColor(this, color)
            this.pForegroundColor = color;
            this.Box.BackgroundColor = color;
        end
        function color = get.ForegroundColor(this)
            color = this.Box.BackgroundColor;
        end
        
        function set.HighlightColor(this, color)
            this.Box.HighlightColor = color;
        end
        function color = get.HighlightColor(this)
            color = this.Box.HighlightColor;
        end
        
        function set.Value(this, value)
            if value < this.pMinimum
                value = this.pMinimum;
            elseif value > this.pMaximum
                value = this.pMaximum;
            end
            this.pValue = value;
            doLayout(this);
            notify(this, 'ValueChanged');
        end
        function value = get.Value(this)
            value = this.pValue;
        end
        
        function set.MajorStep(this, step)
            this.pMajorStep = step;
            doLayout(this);
        end
        function step = get.MajorStep(this)
            step = this.pMajorStep;
        end
        
        function set.Units(this, units)
            this.Panel.Units = units;
        end
        function units = get.Units(this)
            units = this.Panel.Units;
        end
        
        function set.Position(this, pos)
            % The width and height can be set to 0 from the scrollable
            % layout when the figure is tiny.  Force them to 1 to avoid
            % errors, they will not be visible.
            pos(find(pos(3:4) <= 0) + 2) = 1;
            this.Panel.Position = pos;
        end
        function pos = get.Position(this)
            pos = this.Panel.Position;
        end
        
        function set.Parent(this, parent)
            this.Panel.Parent = parent;
            
            % Cache the figure for quick access later.
            this.Figure = ancestor(parent, 'figure');
        end
        function parent = get.Parent(this)
            parent = this.Panel.Parent;
        end
        
        function set.Visible(this, vis)
            this.Panel.Visible = vis;
        end
        function vis = get.Visible(this)
            vis = this.Panel.Visible;
        end
        
        function set.Tag(this, tag)
            this.Panel.Tag = [tag 'Panel'];
            this.Box.Tag   = [tag 'Box'];
        end
        function tag = get.Tag(this)
            tag = this.Panel.Tag;
            tag(end-4:end) = [];
            if isempty(tag)
                tag = '';
            end
        end
    end
    
    methods (Access = protected)
        function panelButtonDown(this, ~, ~)
            point  = this.Figure.CurrentPoint;
            boxPos = matlabshared.application.getPositionRelativeToFigure(this.Box, this.Figure);
            min    = this.pMinimum;
            max    = this.pMaximum;
            step   = this.pMajorStep * (max - min);
            if this.Position(3) > this.Position(4)
                % Horizontal
                if point(1) < boxPos(1)
                    step = -step;
                end
            else
                % Vertical
                if point(2) < boxPos(2)
                    step = -step;
                end
            end
            this.Value = this.pValue + step;
        end
        
        function boxButtonDown(this, ~, ~)
            fig = this.Figure;
            
            % Cache old motion fcn and put in custom.  There is no event
            % that will give the correct CurrentPoint.
            this.OldPointer = fig.Pointer;
            
            % Listen for mouse release to exit mode
            this.MouseMotionListener.Enabled = true;
            this.MouseReleaseListener.Enabled = true;
            
            % Cache the initial figure location and value of the scrollbar
            this.InitialPoint =  get(0, 'PointerLocation');
            this.InitialValue = this.pValue;
            
            % Update the background of the box with the highlight color to
            % indicate that it is being moved.
            this.Box.BackgroundColor = this.HighlightColor;
            
            % 'right' and 'bottom' do not look right on linux/mac.  Use the
            % 'hand' instead.
            if ispc
                pos = this.Panel.Position;
                if pos(3) > pos(4)
                    ptr = 'right';
                else
                    ptr = 'bottom';
                end
            else
                ptr = 'hand';
            end
            fig.Pointer = ptr;
        end
        
        function onMouseRelease(this, ~, ~)
            
            % Restore properties
            this.MouseReleaseListener.Enabled = false;
            this.MouseMotionListener.Enabled  = false;
            
            fig = this.Figure;
            fig.Pointer              = this.OldPointer;
            this.Box.BackgroundColor = this.pForegroundColor;
        end
        
        function onMouseMotion(this, ~, ~)
            difference =  get(0, 'PointerLocation') - this.InitialPoint;
            
            min   = this.pMinimum;
            max   = this.pMaximum;
            range = max - min;
            
            pos = getpixelposition(this.Panel);
            if pos(3) > pos(4)
                % Horizontal
                difference = difference(1) / pos(3) * range;
            else
                % Vertical
                difference = difference(2) / pos(4) * range;
            end
            this.Value = this.InitialValue + difference * (1 + this.MajorStep);
        end
        
        function resizeCallback(this, ~, ~)
            doLayout(this);
        end
        
        function doLayout(this)
            panelPosition = this.Panel.Position;
            step  = this.MajorStep * 4;
            min   = this.pMinimum;
            range = this.pMaximum - min;
            value = this.pValue;
            
            if range <= 0
                return
            end
            
            if panelPosition(3) > panelPosition(4)
                % HORIZONTAL SCROLLBAR
                width = step / (1 + step);
                pixelWidth = width * panelPosition(3);
                if pixelWidth < panelPosition(4)
                    width = panelPosition(4) / panelPosition(3) * 3 / 4;
                end
                x = (value - min) / (range * (1 + width));
                y = 0;
                width = width / (1 + width);
                height = 1;
            else
                % VERTICAL SCROLLBAR
                height = step / (1 + step);
                pixelHeight = height * panelPosition(4);
                if pixelHeight < panelPosition(3)
                    height = panelPosition(3) / panelPosition(4) * 3 / 4;
                end
                x = 0;
                y = (value - min) / (range * (1 + height));
                width = 1;
                height = height / (1 + height);
            end
            % Work around webfigure bug that requires pixels by doing the
            % conversion from normalized to pixels.
            set(this.Box, 'Position', [x y width height] .* panelPosition([3 4 3 4]) + [1 1 0 0]);
        end
    end
end

% [EOF]
