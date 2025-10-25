classdef RadioButton < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    % RadioButton Widget will be undocumented.
    % This will act as an internal widget for RadioGroup.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        %Text - dependent 'Text' property of RadioButton widget.
        %Represents a label for RadioButton.
        Text
    end
    
    properties (Access = public, Dependent, SetObservable)
        %Value - The logical value of current state of Radio button,
        %true value indicates this radio button is "selected" and false
        %indicates "deselected"
        Value
    end
    
    methods(Access= protected)
        function obj = RadioButton(varargin)
            %RadioButton - constructor to set widget defaults
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            [pW, pH] = obj.getParentSize();
            obj.Position = [pW*.1 pH*.5 pW-(pW*0.1) 20];
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.RadioButtonText;
            obj.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            %getInstance - returns instance of RadioButton object
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    
    %% Property setter and getters
    methods
        function text = get.Text(obj)
            %get.Text - get radiobutton text from peer.
            
            text = obj.getText();
        end
        
        function value = get.Value(obj)
            %get.Text - get radiobutton value from peer.
            
            value = logical(obj.getValue());
        end
        
        function set.Text(obj, text)
            %set.Text - set radiobutton value.
            
            obj.validateStringInput(text);
            obj.setText(text);
        end
        
        function set.Value(obj, val)
            %set.Value - set radiobutton value as logical or 1 or 0.
            
            validateattributes(val, {'logical','double'},...
                {'nonempty','binary'})
            obj.setValue(val);
        end
    end
    
    methods(Abstract, Access = protected)
        %setText - Technology specific implementation for setting text.
        setText(obj, text);
        
        %setValue - Technology specific implementation for setting value.
        setValue(obj, text);
        
        %getText - Technology specific implementation for getting text.
        text = getText(obj);
        
        %getValue - Technology specific implementation for getting value.
        value = getValue(obj);
    end
    
end