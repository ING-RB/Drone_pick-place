classdef DatePickerAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    
    % Adapter for Date Picker
    
    % Copyright 2013-2017 The MathWorks, Inc.
    
    properties(SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {'Limits', 'DisabledDates', 'DisabledDaysOfWeek', 'DisplayFormat'};
        
        % the "Value" property of the component
        ValueProperty = 'Value';
        
        ComponentType = 'matlab.ui.control.DatePicker';
    end
    
    
    % ---------------------------------------------------------------------
    % Constructor & Initial Value Setting
    % ---------------------------------------------------------------------
    methods
        function obj = DatePickerAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Method to return a status of whether the value
    % represents the default value of the component. If isDefault
    % returns true, no code will be generated for that property
    % ---------------------------------------------------------------------
    methods
        function isDefaultValue = isDefault(obj,componentHandle,propertyName, defaultComponent)
            % ISDEFAULT - Returns a true or false status based on whether
            % the value of the component corresponding to the propertyName
            % inputted is the default value.  If the value returned is
            % true, then the code for that property will not be displayed
            % in the code at all 
            
            value = componentHandle.(propertyName);
            
            defaultValue = defaultComponent.(propertyName);
            
            % If the current value and the default value of the
            % component are the same,isDefaultValue should be true
            % override to compare NaTs using isequaln
            if strcmp('Value', propertyName)
                isDefaultValue = isequaln(value, defaultValue);          
            else
                % for all other properties call super
               isDefaultValue = isDefault@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj,componentHandle,propertyName, defaultComponent);
            end            
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)               
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/DatePickerModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            codeSnippet = sprintf('uidatepicker(%s)', parentName);
        end
    end
    
    % ---------------------------------------------------------------------
    % a method called at AppDesigner startup to retrieve the component's
    % dynamic properties
    % ---------------------------------------------------------------------    
    methods(Static)
        function dynamicProperties = getDynamicProperties(~)

            % use a DatePicker object and controller to get the correct displayFormat, 
            % inputFormat and viewLanguage
            dp = matlab.ui.control.DatePicker;
            displayFormat = dp.DisplayFormat;
            dateObject = datetime('today');
            inputFormat = matlab.ui.control.internal.controller.DatePickerController.getInputFormatForView(displayFormat);
            viewLanguage = matlab.ui.control.internal.controller.DatePickerController.getViewLanguage();
            
            % create the dynamic properties struct to pass to the client
            dynamicProperties = struct('InputFormat', inputFormat,...
                                       'DisplayFormat',displayFormat,...
                                       'ViewLanguage',viewLanguage);            
        end
    end
end