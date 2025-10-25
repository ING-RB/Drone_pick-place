classdef LampAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for Lamp
    
    % Copyright 2013-2016 The MathWorks, Inc.
  
    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {};
        
        % the "Value" property of the component
        ValueProperty = 'Color';        
           
        ComponentType = 'matlab.ui.control.Lamp';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = LampAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)        
        function adapter = getJavaScriptAdapter()
            adapter =  'uicomponents_appdesigner_plugin/model/LampModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
            codeSnippet = sprintf('uilamp(%s)', parentName);                        
        end
    end
end

