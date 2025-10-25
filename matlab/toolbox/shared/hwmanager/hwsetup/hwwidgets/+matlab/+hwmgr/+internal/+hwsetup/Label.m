classdef Label < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.FontProperties & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %LABEL Provides a LABEL widget as a result of calling
    %getInstance. LABEL widget provides an option for the user to add a
    %Label.
    %
    %   LABEL Widget Properties
    %   Position          -Location and Size [left bottom width height]
    %   Visible           -Widget visibility specified as 'on' or 'off'
    %   Text              -String label for the LABEL
    %   TextAlignment     -Justification of the Text property specified as a string - ('center', 'left', 'right')
    %   FontSize          -Size of the font
    %   FontWeight        -font thickness (normal, bold)
    %   Tag               -Unique identifier for the LABEL widget.
    %   VerticalAlignment -Vertical Alignment of the label within its parent ('top','center' or 'bottom').

    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   l = matlab.hwmgr.internal.hwsetup.Label.getInstance(p);
    %   l.Position = [20 80 200 20];
    %   l.Text = 'MyLabel!';
    %   l.FontSize = 12;
    %   l.FontWeight = 'bold';
    %   l.show();
    %   or
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   l = matlab.hwmgr.internal.hwsetup.Label.getInstance(w);
    %   l.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Text provides Static text displayed to the user as Label.
        Text
        % Text alignment(center, left, right)
        TextAlignment
        % Verical alignment(center, top, bottom)
        VerticalAlignment
    end
    
    methods(Access = protected)
        function obj = Label(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            % Set defaults
            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.LabelPosition;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.Peer,'BackgroundColor',matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput);
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.LabelText;
            obj.TextAlignment = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.LabelTextAlignment;
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    
    %% Property setter and getters
    methods
        function text = get.Text(obj)
            text = obj.getText();
        end
        
        function value = get.TextAlignment(obj)
            value = obj.getTextAlignment();
        end
        
        function set.Text(obj, text)
            if iscell(text) && (~iscellstr(text) && ~isstring(text))
                error(message('hwsetup:widget:InvalidDataType', 'Text',...
                    'cell array of character vectors or string array'))
            end
            validateattributes(text, {'char', 'string', 'cell'},{});
            obj.setText(text);
        end
        
        function set.TextAlignment(obj, value)
            lowerValue = validatestring(value, {'center', 'left', 'right'});
            obj.setTextAlignment(lowerValue);
        end

        function set.VerticalAlignment(obj, value)
            obj.validateStringInput(value);
            set(obj.Peer, 'VerticalAlignment', value);
        end
        
        function value = get.VerticalAlignment(obj)           
            value = get(obj.Peer, 'VerticalAlignment') ;
        end

    end
    
    methods(Abstract, Access = protected)
        setText(obj, text)
        setTextAlignment(obj, value)
        value = getTextAlignment(obj)
        text = getText(obj)
    end
end