classdef SliderAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for a Slider component

    % Copyright 2013-2025 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {'Limits','MajorTicks','MajorTickLabels','Orientation','ValueChangedFcn','ValueChangingFcn','MinorTicks'}
        
        % the "Value" property of the component
        ValueProperty = 'Value';
        
        ComponentType = 'matlab.ui.control.Slider';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = SliderAdapter(varargin)
             obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'appdesigner.internal.componentcontroller.DesignTimeSliderController';
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)                
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/SliderModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
            codeSnippet = sprintf('uislider(%s)', parentName);                        
        end
    end

    % ---------------------------------------------------------------------
    % Code Gen Method to return a status of whether the value
    % represents the default value of the component. If isDefault
    % returns true, no code will be generated for that property
    % ---------------------------------------------------------------------
    methods
        function isDefaultValue = isDefault(obj, componentHandle, propertyName, defaultComponent)
            value = componentHandle.(propertyName);

            limitsValue = componentHandle.Limits;

            if (strcmp('Step', propertyName))
                defaultValue = (limitsValue(2) - limitsValue(1))/1000;
                if isequal(value, defaultValue) && strcmp(componentHandle.StepMode, 'auto')
                    isDefaultValue = true;
                else
                    isDefaultValue = false;
                end
            else
                isDefaultValue = isDefault@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj, componentHandle, propertyName, defaultComponent);
            end
        end
    end
end

