classdef EditText < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %EDITTEXT The EDITTEXT widget provides a text entry field for a
    %user to enter or change values.
    %
    %   EDITTEXT Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   String          -text in the EDITTEXT box
    %   StringAlignment -text alignment(center, left, right)
    %   FontSize        -Size of the font
    %   FontWeight      -font thickness (normal, bold)
    %   ValueChangedFcn -Callback that runs when the text is changed and a
    %                    user presses enter or clicks off the text box
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   et = matlab.hwmgr.internal.hwsetup.EditText.getInstance(p);
    %   et.Position = [20 80 200 20];
    %   et.Text = 'Enter Text Here!';
    %   et.ValueChangedFcn = @(~,~)disp('Value Changed!')
    %   et.FontWeight = 'bold';
    %   et.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2019 The MathWorks, Inc.
    properties(Dependent)
        %text in the EDITTEXT box
        Text
        TextAlignment %text alignment(center, left, right)
    end
    
    properties
        %Callback that runs when the text is changed and a
        %user presses enter or clicks off the text box
        ValueChangedFcn
    end
    
    methods(Access = protected)
        function obj = EditText(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            
            %Default Values
            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.EditTextPosition;
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.EditTextText;
            obj.TextAlignment = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.EditTextTextAlignment;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            obj.setCallback();
        end 
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end
    
    methods
        function value = get.Text(obj)
            value = obj.getText();
        end
        
        function value = get.TextAlignment(obj)
            value = obj.getTextAlignment();
        end
        
        function set.Text(obj, value)
            obj.validateStringInput(value);
            obj.setText(value);
        end
        
        function set.TextAlignment(obj, value)
            lowerValue = validatestring(value, {'center', 'left', 'right'});
            obj.setTextAlignment(lowerValue);
        end
        
        function set.ValueChangedFcn(obj, value)
            %if the value is empty, clear out ValueChangedFcn
            if isempty(value)
                obj.ValueChangedFcn = '';
            else
                %if the value is not empty, ensure it is a valid function handle
                %and then set it to ValueChangedFcn
                validateattributes(value, {'function_handle'}, {});
                obj.ValueChangedFcn = value;
            end
        end
    end
    
    methods(Abstract, Access = protected)
        setCallback(obj);
        setTextAlignment(obj, value)
        setText(obj, value)
        value = getTextAlignment(obj)
        value = getText(obj)
    end
end