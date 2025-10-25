classdef ListBoxAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for a ListBox component

    % Copyright 2014-2016 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {'Items','ItemsData'};
        
        % the "Value" property of the component
        ValueProperty = 'Value';
        
           
        ComponentType = 'matlab.ui.control.ListBox';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ListBoxAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)      
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ListBoxModel';
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
            codeSnippet = sprintf('uilistbox(%s)', parentName);
        end         
    end
end

