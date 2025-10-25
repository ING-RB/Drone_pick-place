classdef ColorPickerAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter

    % Adapter for Color Picker

    % Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=protected, GetAccess=public)
        % an array of properties where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {'Value', 'Icon', 'ValueChangedFcn'};

        ValueProperty = 'Value';

        ComponentType = 'matlab.ui.control.ColorPicker';
    end

    % ---------------------------------------------------------------------
    % Constructor & Initial Value Setting
    % ---------------------------------------------------------------------
    methods
        function obj = ColorPickerAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end

        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'appdesigner.internal.componentcontroller.DesignTimeColorPickerController';
        end
    end

    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ColorPickerModel';
        end
    end

    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
            codeSnippet = sprintf('uicolorpicker(%s)', parentName);                        
        end
    end
end
