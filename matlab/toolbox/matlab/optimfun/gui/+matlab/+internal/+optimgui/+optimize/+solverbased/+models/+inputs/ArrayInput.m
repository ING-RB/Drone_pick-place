classdef ArrayInput < matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    % obj = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, Name, FilterVariablesFcn)
    % constructs an ArrayInput with the specified State, Name, and FilterVariablesFcn properties.
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    % An ArrayInput's Value property is a (1, :) char of a variable name set from a filtered WorkspaceDropDown
    
    methods (Access = public)
        
        function obj = ArrayInput(State, Name, FilterVariablesFcn, TooltipID, Widget)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput(State, Name);
        
        % Support specifying a certain widget for this input type.
        % Else, use a WorkspaceDropDown
        if nargin > 4
            obj.Widget = Widget;
        else
            obj.Widget = 'matlab.ui.control.internal.model.WorkspaceDropDown';
        end
        
        % Set FilterVariablesFcn and Tooltip widget properties from input arguments
        obj.WidgetProperties.FilterVariablesFcn = FilterVariablesFcn;
        obj.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', TooltipID);
        
        % Pull the default value from the Static constants class
        obj.DefaultValue = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        end
        
        function tf = isSet(obj)
        
        % Compare Value property to the UnsetDropDownValue
        tf = ~strcmp(obj.Value, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue);
        end
        
        function code = generateCode(obj)
        
        % If the ArrayInput is set, return the Value property.
        % Else, return empty brackets
        if obj.isSet
            code = matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value);
        else
            code = '[]';
        end
        end
    end
end
