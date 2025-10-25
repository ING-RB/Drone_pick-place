classdef ContextMenuAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter 
    % Adapter for a ContextMenu component
    
    % Copyright 2019 - 2023 The MathWorks, Inc.
    
    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {};
        
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.container.ContextMenu';
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ContextMenuAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function propertyNames = getCodeGenPropertyNames(obj, componentHandle)
            
            import appdesigner.internal.componentadapterapi.VisualComponentAdapter;
            
            % Get all properties as a struct and get the property names
            % properties as a starting point
            propertyValuesStruct = get(componentHandle);
            allProperties = fieldnames(propertyValuesStruct);

            % Properties that are always ignored and are never set when
            % generating code
            %
            % Remove these from both the properties and order specific
            % properties
            
            readOnlyProperties = VisualComponentAdapter.listNonPublicProperties(componentHandle);

            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, {...                                
                'Position'                
                }];
            
            % Create the master list
            propertyNames = ...
            [setdiff(allProperties, ...
            [ignoredProperties], 'stable')];

        end
    end
    
      methods(Access = protected)
        
        function defaultValues = customizeComponentDesignTimeDefaults(~, defaultValues, ~)
            % Change ObjectID to be empty
            defaultValues.ObjectID = '';
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ContextMenuModel';
        end
        
        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'matlab.ui.internal.DesignTimeContextMenuController';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)            
            codeSnippet = sprintf('uicontextmenu(%s)', parentName);
        end         
    end
end

