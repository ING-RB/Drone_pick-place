classdef CheckBoxTreeAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for a Checkbox Tree component

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {};

        % the "Value" property of the component
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.container.CheckBoxTree';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = CheckBoxTreeAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
    end

    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)       
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/CheckBoxTreeModel';
        end
    end

    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)

        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            codeSnippet = sprintf('uitree(%s, ''checkbox'')', parentName);
        end
    end

    methods
        function propertyValueString = getPropertyValueString(obj, componentModel, propertyName)
            if strcmp(propertyName, 'CheckedNodes') && numel(componentModel.CheckedNodes) > 0
                propertyValueString = "[";
                m = 1;
                propertyValueString = append(propertyValueString, componentModel.CheckedNodes(m).DesignTimeProperties.CodeName);

                while m < numel(componentModel.CheckedNodes)
                    m = m + 1;
                    propertyValueString = append(propertyValueString, " ");
                    propertyValueString = append(propertyValueString, componentModel.CheckedNodes(m).DesignTimeProperties.CodeName);
                end

                propertyValueString = append(propertyValueString, "]");
            else
                propertyValueString = getPropertyValueString@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj, componentModel, propertyName);
            end

        end
    end

end
