classdef Dialog < matlabshared.application.Component
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        hPanel
        hApply
        Layout
        HasUnappliedChanges = false;
    end
    
    methods
        
        function this = Dialog(varargin)
            this@matlabshared.application.Component(varargin{:});
            refresh(this);
        end
        
        function open(this)
            figure(this.Figure);
        end
        
        function close(this)
            cancelCallback(this);
        end
        
        function update(this)
            if this.HasUnappliedChanges
                enab = 'on';
            else
                enab = 'off';
            end
            set(this.hApply, 'Enable', enab);
        end
        
        function refresh(~)
            % NO OP - overload to pull up settings from the datamodel.
        end
    end
    
    methods (Hidden)
        function b = isDocked(this)
            b = false;
        end
        
        function genericCallback(this, ~, ~)
            this.HasUnappliedChanges = true;
            update(this);
        end
        
        function okCallback(this, ~, ~)
            if applyCallback(this)
                cancelCallback(this);
            end
        end
        
        function onKeyPress(this, ~, ev)
            if strcmp(ev.Key, 'escape')
                cancelCallback(this);
            end
        end
        
        function cancelCallback(this, ~, ~)
            this.Figure.Visible = 'off';
            refresh(this);
        end
        
        function success = applyCallback(this, ~, ~)
            success = apply(this);
            if success
                this.HasUnappliedChanges = false;
                update(this);
            end
        end
    end
    
    methods (Access = protected)
        function fig = createFigure(this, varargin)
            fig = createFigure@matlabshared.application.Component(this, ...
                'CloseRequestFcn', @this.cancelCallback, varargin{:});
            
            this.hPanel = uipanel(fig);
            
            layout = matlabshared.application.layout.GridBagLayout(fig, ...
                'HorizontalGap', 3, ...
                'VerticalGap', 3, ...
                'HorizontalWeights', [1 0 0 0], ...
                'VerticalWeights',   [1 0]);
            add(layout, this.hPanel,  1, [1 4], 'Fill', 'Both');
            
            this.Layout = layout;
            
            createButtons(this, fig, layout);
            
            update(layout, true);
        end
        
        function createButtons(this, fig, layout)
            hok = uicontrol(fig, ...
                'String', getString(message('MATLAB:uistring:popupdialogs:OK')), ...
                'Tag', 'OK', ...
                'Callback', @this.okCallback);
            hcancel = uicontrol(fig, ...
                'String', getString(message('Spcuilib:application:Cancel')), ...
                'Tag', 'Cancel', ...
                'Callback', @this.cancelCallback);
            this.hApply = uicontrol(fig, ...
                'String', getString(message('Spcuilib:application:Apply')), ...
                'Tag', 'Apply', ...
                'Callback', @this.applyCallback);
            
            buttonWidth = layout.getMinimumWidth([hok hcancel this.hApply]) + 20;
            
            add(layout, hok,          2, 2, 'MinimumWidth', buttonWidth);
            add(layout, hcancel,      2, 3, 'MinimumWidth', buttonWidth);
            add(layout, this.hApply,  2, 4, 'MinimumWidth', buttonWidth);
        end
    end
end
