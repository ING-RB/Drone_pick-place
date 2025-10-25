classdef PushToolAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for Push Tool
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess=protected, GetAccess=public)
        % Properties that must be set in a particular order.  This order is
        % used for Code Generation and design-time component creation
        OrderSpecificProperties = {}
        
        % The "Value" property of the component
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.container.toolbar.PushTool';
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = PushToolAdapter(varargin)
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
            % read-only properties, and CData/ButtonDownFcn.
            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, {...
                'ButtonDownFcn',...
                'CData',...
                }];
            
            % Create the master list by removing the ignored properties
            % from the full list.
            propertyNames = setdiff(allProperties, ignoredProperties, 'stable');
        end
        
        function defaultValues = getComponentRunTimeDefaults(obj, theme, parentType)
            arguments
                obj
                theme = 'unthemed'
                parentType = ''
            end
            % GETCOMPONENTRUNTIMEDEFAULTS - Overload the base  getComponentRunTimeDefaults & pass
            % parent argument to get the appropriate Themed defaults.

            
            % obj.ComponentType will be 'matlab.ui.container.toolbar.PushTool'
            defaultValues = getComponentRunTimeDefaults@appdesigner.internal.componentadapterapi.mixins.ComponentDefaults(obj, theme, 'matlab.ui.container.Toolbar');
        end
        
    end
    
    methods(Access = protected)
        function parent = createDesignTimeParentComponent(obj)
            % CREATEDESIGNTIMEPARENTCOMPONENT - Overload the base method
            % because push tool cannot be parented to a uifigure.  Create
            % an appropriate parent for the push tool.
            
            % Create a UIFigure by calling the super-class
            uiFigure = createDesignTimeParentComponent@...
                appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj);
            
            % Use the toolbar adapter to create a toolbar as a child of the UIFigure
            toolbarAdapter = appdesigner.internal.componentadapter.uicomponents.adapter.ToolbarAdapter();
            parent = toolbarAdapter.createDesignTimeComponent(uiFigure);
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)               
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/PushToolModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(~, ~, parentName)
            codeSnippet = sprintf('uipushtool(%s)', parentName);
        end
    end
end