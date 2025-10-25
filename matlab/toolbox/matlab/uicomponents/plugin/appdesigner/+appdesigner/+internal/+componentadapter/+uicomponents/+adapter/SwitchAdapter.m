classdef SwitchAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for Slider Switch
    
    % Copyright 2013-2016 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {'Items','ItemsData','Orientation'}
        
        % the "Value" property of the component
        ValueProperty = 'Value';
        
        ComponentType = 'matlab.ui.control.Switch';
    end

    % ---------------------------------------------------------------------
    % Constructor methods
    % ---------------------------------------------------------------------
    methods
        function obj = SwitchAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'appdesigner.internal.componentcontroller.DesignTimeStateComponentController';
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/SliderSwitchModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        % ---------------------------------------------------------------------
        % Code Gen Method that can be overriddeent to provide option to
        % ignore specific property names for code gen
        % componentIgnoredPropertyList should be a row vector of cellstr
        % ---------------------------------------------------------------------
        function componentIgnoredPropertyList = getCodeGenIgnoredComponentPropertyNames()
            componentIgnoredPropertyList = {'ValueIndex'};
        end
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
          codeSnippet = sprintf('uiswitch(%s, ''slider'')', parentName);
        end 
    end
end

