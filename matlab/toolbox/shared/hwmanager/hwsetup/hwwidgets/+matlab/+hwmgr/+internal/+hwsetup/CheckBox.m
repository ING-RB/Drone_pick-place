classdef CheckBox < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %CHECKBOX Provides a CHECKBOX widget as a result of calling
    %getInstance. CHECKBOX widget provides a checkbox utility for the user
    %with callback.
    %
    %   CHECKBOX Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Text            -String label for the CHECKBOX.
    %   Value           -Gives the logical state of checkbox.(Checked = 1, Unchecked = 0)
    %   ValueChangeFcn  -Callback function when checkbox value changes.
    %   Tag             -Unique identifier for the checkbox widget.
    %   WordWrap        -Enable or disable WordWrap for checkbox label (specified as 'on' or 'off')
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   cb = matlab.hwmgr.internal.hwsetup.CheckBox.getInstance(p);
    %   cb.Position = [20 80 100 20];
    %   cb.String = 'MyCheckBox';
    %   cb.show();
    %   or
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   cb = matlab.hwmgr.internal.hwsetup.CheckBox.getInstance(w);
    %   cb.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    %   Copyright 2016 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Text property Specifies the string to be displayed on the checkbox.
        Text
        %WordWrap property when configured to on enables the text to get
        %wrapped around instead of getting cropped (can be set to 'on' or 'off')
        WordWrap
    end
    
    properties (Access = public, Dependent, SetObservable)
        % Value - The current logical state of the checkbox widget,
        % true value indicates "checked" and false indicates "unchecked"
        Value
    end
    
    properties(Access = public)
        % ValueChangedFcn - The function callback that gets executed when
        % checkbox value changes.
        ValueChangedFcn
    end
    
    methods(Access = protected)
        function obj = CheckBox(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            % Set defaults
            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.CheckBoxPosition;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.CheckBoxText;
            obj.Value = false;
            obj.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
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
        %getters
        function text = get.Text(obj)
            text = obj.getText();
        end
        
        function value = get.Value(obj)
            value = logical(obj.getValue());
        end

        function value = get.WordWrap(obj)           
            value = get(obj.Peer, 'WordWrap') ;
        end
        
        % setters
        function set.Text(obj, text)
            obj.validateStringInput(text);
            obj.setText(text);
        end
        
        function set.Value(obj, val)
            validateattributes(val, {'logical','double'}, {'nonempty','binary'})
            obj.setValue(val);
        end

        function set.WordWrap(obj, value)                        
            set(obj.Peer, 'WordWrap', value);
        end

    end
    
    methods(Abstract, Access = protected)
        setText(obj, text);
        setValue(obj, text);
        
        text = getText(obj);
        value = getValue(obj);
        
        setCallback(obj);
        valueChangedCbk(obj);
    end
end