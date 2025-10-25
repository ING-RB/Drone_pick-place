classdef Button < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.FontProperties & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %BUTTON Provides a BUTTON(Push Button) widget as a result of calling
    %getInstance. BUTTON widget provides a push button utility for the user
    %with callback.
    %
    %   BUTTON Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Text            -String label for the BUTTON.
    %   ButtonPushedFcn -Callback function when button pushed.
    %   Tag             -Unique identifier for the button widget.
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   b = matlab.hwmgr.internal.hwsetup.Button.getInstance(p);
    %   b.Position = [20 80 100 20];
    %   b.Text = 'MyButton';
    %   b.show();
    %   or
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   b = matlab.hwmgr.internal.hwsetup.Button.getInstance(w);
    %   b.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Text property specifies the string to be displayed on the button
        Text

        % Icon property specifies the icon path to be displayed on the
        % button
        Icon
    end
    
    properties(Access = public)
        % ButtonPushedFcn - The function callback that gets executed when
        % button is pushed.(Callback will be triggered after the push button is released)
        % When the user pushes the button twice quickly,
        % ButtonPushedFcn will be invoked twice.
        ButtonPushedFcn
    end
    
    methods(Access = protected)
        function obj = Button(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            % Set defaults
            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.UIControlPosition;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.ButtonText;
            obj.setCallback();
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    
    %% Property setter and getters
    methods
        
        function click(obj)
            obj.buttonPushedCbk();
        end
        
        function set.ButtonPushedFcn(obj, fcn)
            validateattributes(fcn, {'function_handle', 'cell'},{});
            obj.ButtonPushedFcn = fcn;
        end
        function text = get.Text(obj)
            text = obj.getText();
        end
        
        function set.Text(obj, text)
            obj.validateStringInput(text);
            obj.setText(text);
        end

        function icon = get.Icon(obj)         
            icon = obj.Icon;
        end

        function set.Icon(obj, icon)
            % SET.ICON sets Icon property of Peer using legacy icon files
            
            obj.Peer.Icon = icon;
        end

        function setIconID(obj, icon, width, height)
            % SETICONID adds themeable icons using id

            matlab.ui.control.internal.specifyIconID(obj.Peer, icon, width, height);
        end
    end
    
    methods(Abstract, Access = 'protected')
        setText(obj, text);
        text = getText(obj);
        
        setCallback(obj);
    end
    
    methods(Abstract)
        buttonPushedCbk(obj);
    end
end