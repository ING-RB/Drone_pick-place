classdef ContinuousKnobAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for a Continuous Knob component

    % Copyright 2013-2016 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time. 
        OrderSpecificProperties = {'Limits','MajorTicks','MajorTickLabels','ValueChangedFcn','ValueChangingFcn','MinorTicks'}
        
        % the "Value" property of the component
        ValueProperty = 'Value';
        
        ComponentType = 'matlab.ui.control.Knob';
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ContinuousKnobAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        function controllerClass = getComponentDesignTimeController(obj)
            controllerClass = 'appdesigner.internal.componentcontroller.DesignTimeContinuousKnobController';
        end
    end
    
    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)                        
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/ContinuousKnobModel';
        end
    end
    
    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)
        
        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            
           codeSnippet = sprintf('uiknob(%s, ''continuous'')', parentName);                                                                                    
        end
    end
end

