classdef AbstractLayout < handle
    %AbstractLayout   Define the AbstractLayout class.
    
    %   Copyright 2017 The MathWorks, Inc.
    
    properties
        DelayLayout = false;
    end
    
    properties (SetAccess = private)
        Panel;
    end
    
    properties (Access = protected)
        Invalid = true;
        OldPosition;
    end
    
    properties (Constant)
        LabelOffset = 3;
        ButtonPadding = 10;
    end

    properties (GetAccess = protected, Constant)
        CONSTRAINTSTAG = 'Layout_Manager_Constraints';
    end
    
    events
        LayoutPerformed
    end
    
    methods
        
        function this = AbstractLayout(hPanel)
            %AbstractLayout   Construct the AbstractLayout class.
            
            this.Panel = hPanel;
        end
        
        function set.DelayLayout(this, delay)
            this.DelayLayout = delay;
            if ~delay
                update(this);
            end
        end
        
        function add(this, h, varargin)
            %ADD   Add the component to the layout manager.
                        
            % Make sure there isn't already a component in the location.
            hOld = getComponent(this, varargin{:});
            if ~isempty(hOld) && hOld ~= double(h)
                error(message('Spcuilib:application:OccupiedLocationError'));
            end
            
            if ishghandle(h)
                set(h, 'Parent', this.Panel);
            end
        end
        
        function update(this, force)
            %UPDATE   Update the layout.
            
            if nargin < 2
                force = 'noforce';
            end
            
            % When UPDATE is called, we assume the layout is dirty.
            if this.Invalid || strcmpi(force, 'force')
                
                % Nothing to do if the panel is invisible, to avoid multiple updates.
                if strcmpi(get(this.Panel, 'Visible'), 'Off') && strcmp(force, 'noforce') || this.DelayLayout
                    return;
                end
                
                layout(this);
                
                notify(this, 'LayoutPerformed');
                
                % The layout is now clean.
                this.Invalid = false;
            end
        end

    end
    
    methods (Static)
        function w = getMinimumWidth(widget)
            if ishghandle(widget, 'uipanel')
                widget = getappdata(widget, 'Label');
                stringProp = 'Text';
                w = 0;
            elseif ishghandle(widget, 'uilabel')
                stringProp = 'Text';
                w = 0;
            else
                stringProp = 'String';
                ext = get(widget, 'Extent');
                if iscell(ext)
                    ext = vertcat(ext{:});
                    w   = max(ext(:, 3));
                else
                    w   = ext(3);
                end
            end
            
            if w > 0
                return;
            end

            if ispc
                factor = get(widget(1), 'FontSize');
            else
                factor = get(widget(1), 'FontSize')/8*9.6;
            end
            % Most characters take up 1 full width
            % . 1 f i l t, all take up 1/2 a space.
            allWidths = [...
                1.4 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  ...
                0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  ...
                0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0  ...
                0.0 0.4 0.3 0.5 0.8 0.8 1.3 0.9 0.3 0.5  ...
                0.5 0.5 0.8 0.4 0.5 0.4 0.4 0.8 0.8 0.8  ...
                0.8 0.8 0.8 0.8 0.8 0.8 0.8 0.4 0.4 0.8  ...
                0.8 0.8 0.8 1.4 1.0 0.9 0.9 0.9 0.8 0.8  ...
                1.0 0.9 0.3 0.7 0.9 0.8 1.0 0.9 1.0 0.8  ...
                1.0 0.9 0.9 0.8 0.9 1.0 1.3 0.9 1.0 0.9  ...
                0.4 0.4 0.4 0.7 0.8 0.5 0.8 0.8 0.8 0.8  ...
                0.8 0.5 0.8 0.8 0.3 0.3 0.7 0.3 1.0 0.8  ...
                0.8 0.8 0.8 0.5 0.8 0.4 0.8 0.8 1.3 0.8  ...
                0.8 0.8 0.5 0.3 0.5 0.8 0.0 0.0 0.0 0.7  ...
                0.7 0.7 1.2 0.7 0.7 0.5 1.2 0.7 0.7 1.4  ...
                0.0 0.0 0.0 0.0 0.3 0.3 0.7 0.7 0.0 0.8  ...
                1.4 0.5 1.3 0.5 0.4 0.8 0.0 0.0 1.0 0.4  ...
                0.3 0.8 0.8 0.9 0.8 0.3 0.8 0.5 1.0 0.5  ...
                0.8 0.8 0.5 1.0 0.8 0.5 0.8 0.5 0.5 0.5  ...
                0.8 0.8 0.5 0.5 0.5 0.7 0.8 1.2 1.3 1.3  ...
                0.8 1.0 1.0 1.0 1.0 1.0 1.0 1.4 0.9 0.8  ...
                0.8 0.8 0.8 0.3 0.3 0.3 0.3 1.0 0.9 1.0  ...
                1.0 1.0 1.0 1.0 0.8 1.0 0.9 0.9 0.9 0.9  ...
                1.0 0.9 0.9 0.8 0.8 0.8 0.8 0.8 0.8 1.3  ...
                0.8 0.8 0.8 0.8 0.8 0.3 0.3 0.3 0.3 0.8  ...
                0.8 0.8 0.8 0.8 0.8 0.8 0.8 0.8 0.8 0.8  ...
                0.8 0.8 0.8 0.8 0.8];
            for index = 1:numel(widget)
                strs = get(widget(index), stringProp);
                if iscell(strs)
                    for iCell=1:numel(strs)
                        str = abs(strs{iCell});
                        if all(str <= numel(allWidths))
                            w = max(w, factor*sum(allWidths(str)));
                        end
                    end
                else
                    str = abs(strs);
                    if all(str <= numel(allWidths))
                        w = max(w, factor*sum(allWidths(str)));
                    end
                end
            end
            
            persistent ax;
            persistent txtObj;
            if w == 0
                if isempty(ax) || isempty(txtObj)
                    ax = uiaxes('Parent',[],'Units','pixels','Visible','off','Internal', true);
                    txtObj = text(ax,1,1,'','Units','pixels', 'FontUnits', 'pixels','Internal', true);
                end
                
                ax.Parent = widget.Parent;
                props = ["FontName", "FontSize", "FontAngle", "FontWeight"];
                if isa(widget, 'matlab.ui.control.UIControl')
                    txtObj.String = widget.String;
                else
                    txtObj.String = widget.Text;
                end
                for propi = 1:length(props)
                    txtObj.(props(propi)) = widget.(props(propi));
                end
                w = ceil(txtObj.Extent(3) * 1.5);
                ax.Parent = [];

            end
        end
    end
    
    methods (Abstract, Access = protected)
        getComponent(this);
        layout(this);
    end
    
    methods
        
        function set.Panel(this, panel)
            
            % This is faster than STRCMPI
            if ~ishghandle(panel) || ...
                    ~any(strcmp(get(panel, 'type'), {'uipanel', 'figure', 'uicontainer'}))
                error(message('Spcuilib:application:InvalidLayoutPanelError'))
            end
            
            % Do this before we create the listeners to avoid accidental firing.
            pos = getpixelposition(panel);
            this.OldPosition = pos(3:4); %#ok<MCSUP>
            
            if matlabshared.application.usingWebFigures
                set(panel, 'AutoResizeChildren', 'off');
            end
            set(panel, 'ResizeFcn', @(hsrc, ev) onResize(this));
            
            this.Panel = panel;
            
            function onResize(this)
                
                newPos = getpixelposition(this.Panel);
                newPos(1:2) = [];
                
                % Only resize if the panel position (width and height) actually changed.
                if ~all(this.OldPosition == newPos)
                    this.OldPosition = newPos;
                    this.Invalid = true;
                    update(this);
                end
            end
        end
    end
    
    methods (Access = protected)
        function panelPosition = getPanelPosition(this)
            hp = this.Panel;
            
            oldResizeFcn = get(hp, 'ResizeFcn');
            set(hp, 'ResizeFcn', '');
            
            panelPosition = getpixelposition(hp);
            
            if ishghandle(hp, 'uipanel')
                % We need to remove the extra spaces taken up by the border
                % which we cannot use.
                panelPosition(3:4) = panelPosition(3:4)-2*get(hp, 'BorderWidth');
            end
            
            set(hp, 'ResizeFcn', oldResizeFcn);
        end
    end
end

% [EOF]
