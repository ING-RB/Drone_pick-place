classdef ToolbarAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for Toolbar
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess=protected, GetAccess=public)
        % Properties that must be set in a particular order.  This order is
        % used for Code Generation and design-time component creation
        OrderSpecificProperties = {}
        
        % The "Value" property of the component
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.container.Toolbar';
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ToolbarAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function propertyNames = getCodeGenPropertyNames(obj, componentHandle)
            % GETCODEGENPROPERTYNAMES - Obtain a list of properties, in the
            % correct order, for which code should be generated
            
            import appdesigner.internal.componentadapterapi.VisualComponentAdapter;
            
            % Get all properties as a struct and then get a list of all property names
            % as a starting point
            propertyValuesStruct = get(componentHandle);
            allProperties = fieldnames(propertyValuesStruct);
            
            % Obtain the read-only properties, which we will never generate
            % code for.
            readOnlyProperties = VisualComponentAdapter.listNonPublicProperties(componentHandle);
            
            % Create a full list of all properties that we do not want to
            % generate code for.  This includes common properties,
            % read-only properties, and ButtonDownFcn/Clipping.
            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, {...
                'ButtonDownFcn',...
                'Clipping',...
                }];
            
            % Create the master list by removing the ignored properties
            % from the full list.
            propertyNames = setdiff(allProperties, ignoredProperties, 'stable');
        end
        
       function controllerClass = getComponentDesignTimeController(obj)
            % GETCOMPONENTDESIGNTIMECONTROLLER - Obtain the MATLAB Class
            % Name / Package location for the component design time controller
            
            controllerClass = 'matlab.ui.internal.DesignTimeToolbarController';
       end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ToolbarModel';
        end        
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(~, ~, parentName)
            codeSnippet = sprintf('uitoolbar(%s)', parentName);
        end
    end
end