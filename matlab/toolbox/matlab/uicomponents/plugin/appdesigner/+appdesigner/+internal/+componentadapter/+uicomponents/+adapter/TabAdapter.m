classdef TabAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for TabGroup
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}
        
        % the "Value" property of the component
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.container.Tab';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        
        function obj = TabAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function defaultValues = getComponentRunTimeDefaults(obj, theme, parentType)
            arguments
                obj
                theme = 'unthemed'
                parentType = ''
            end
            % overload the base  getComponentRunTimeDefaults & pass parent argument to get the appropriate Themed defaults.

            defaultValues = getComponentRunTimeDefaults@appdesigner.internal.componentadapterapi.mixins.ComponentDefaults(obj, theme, 'matlab.ui.container.TabGroup');
        end

        % ---------------------------------------------------------------------
        % Code Gen Method to return an array of property names, in the correct
        % order, as required by Code Gen
        % ---------------------------------------------------------------------
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
                'TooltipString',...
                'UIContextMenu',...
                'Units',...
                }];
            
            % List of properties that should be listed first, as row
            propertiesAtBeginning = { ...
                % AutoResizeChildren should be listed before SizeChangedFcn to avoid the
                % warning message when both have non-default values
                % (AutoResizeChildren off and SizeChangedFcn non-empty).
                'AutoResizeChildren' ...
            };
            
            % Create the master list
            propertyNames = [ ...
                propertiesAtBeginning'; ...
                setdiff(allProperties, ...
                [ignoredProperties, propertiesAtBeginning], 'stable') ...                
            ];
        end
        
        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'matlab.ui.internal.DesignTimeTabController';
        end
    end
    
    methods (Access = protected)
        function parent = createDesignTimeParentComponent(obj)
            % Needs to be parented to TabGroup, and then TabGroup to
            % be under uifigure accordingly so all the default values are
            % initialized correctly
            
            % Create UIFigure as a parent to TabGroup
            uiFigure = createDesignTimeParentComponent@...
                appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj);
            
            % Create TabGroup as a parent to Tab
            tabGroupAdapter = appdesigner.internal.componentadapter.uicomponents.adapter.TabGroupAdapter();
            parent = tabGroupAdapter.createDesignTimeComponent(uiFigure);
        end
        
        function applyCustomComponentDesignTimeDefaults(obj, component)
            % Apply custom design-time component defaults to the component
            %            
            % Set design time properties for Title
            component.Title = getString(message('MATLAB:ui:defaults:TabTitle'));
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function controllerName = getControllerName()
            controllerName = 'matlab.ui.internal.WebTabController';
        end
        
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/TabModel';
        end      
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
            codeSnippet = sprintf('uitab(%s)', parentName);
        end
    end
end

