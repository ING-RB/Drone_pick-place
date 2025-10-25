classdef ImageAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter 
    % Adapter for Image Component

    % Copyright 2018 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}

        % the "Value" property of the component
        ValueProperty = 'ImageSource';
        
        ComponentType = 'matlab.ui.control.Image';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ImageAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
    end

    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)        
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ImageModel';
        end
    end

    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
             codeSnippet = sprintf('uiimage(%s)', parentName);
        end
    end
end