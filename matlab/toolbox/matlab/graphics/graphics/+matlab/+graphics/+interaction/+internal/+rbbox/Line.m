classdef Line < handle
    % A wrapper around the uicontrol text object to create lines
    % This is undocumented and will change in a future release 

    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        UIControl
    end
    
    methods
        function this = Line(f)
            if isWebFigureType(f, 'UIFigure')
                this.UIControl = uilabel(f, 'Visible', 'off', ...
                    'HandleVisibility', 'off', 'Position', [0 0 0 0]);
            else
                this.UIControl = uicontrol(f, 'Style', 'text', 'Visible', 'off',...
                    'Units', 'pixels', 'HandleVisibility', 'off', 'HitTest', 'off', ...
                    'Position', [0 0 0 0]);
            end

            matlab.graphics.internal.themes.specifyThemePropertyMappings(this.UIControl, ...
                    'BackgroundColor', '--mw-graphics-borderColor-axes-primary');
        end
        
        function delete(this)
            this.UIControl.delete();
        end
        
        function position = getPosition(this)
            position = this.UIControl.Position;
        end
        
        function setPosition(this, position)
            this.UIControl.Position = position;
        end
        
        function show(this)
            this.UIControl.Visible = 'on';
        end
        
        function hide(this)
            this.UIControl.Visible = 'off';
        end
        
        function tf = isShown(this)
            tf = (this.UIControl.Visible == 'on');
        end
    end
end

