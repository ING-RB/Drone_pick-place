classdef LinearConstraintInput < matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    % obj = matlab.internal.optimgui.optimize.solverbased.models.inputs.LinearConstraintInput(State, Name) ...
    % constructs a LinearConstraintInput with the specified State and Name properties
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput, matlab.internal.optimgui.optimize.widgets.uiLinearConstraintsWidget
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    % A LinearConstraintInput's Value property is a (1, 1) struct set from a uiLinearConstraintsWidget
    % Value struct fields include:
    %   LHS (1, :) char - Matrix variable name set from a filtered WorkspaceDropDown
    %   RHS (1, :) char - Vector variable name set from a filtered WorkspaceDropDown
    
    methods (Access = public)
        
        function obj = LinearConstraintInput(State, Name)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput(State, Name);
        
        % This widget type bakes in appropriate FilterVariablesFcns and Tooltips
        obj.Widget = 'matlab.internal.optimgui.optimize.solverbased.views.inputs.LinearConstraintView';
        
        % Pull tooltip and label widget properties from catalog
        obj.WidgetProperties.LHSLabel = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Labels', [obj.StatePropertyName, 'LHSLabel']);
        obj.WidgetProperties.RelationLabel = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Labels', [obj.StatePropertyName, 'RelationLabel']);
        obj.WidgetProperties.RHSLabel = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Labels', [obj.StatePropertyName, 'RHSLabel']);
        
        % Pull the default value from the Static constants class
        obj.DefaultValue = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultLinearConstraint;
        end
        
        function tf = isSet(obj)
        
        % Compare LHS and RHS properties to the UnsetDropDownValue
        tf = ~strcmp(obj.Value.LHS, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue) && ...
            ~strcmp(obj.Value.RHS, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue);
        end
        
        function code = generateCode(obj)
        
        % If the LinearConstraintInput is set, return the LHS and RHS fields of the Value struct, ...
        % separated by a comma.
        % Else, return two empty brackets separated by a comma
        if obj.isSet()
            code = [matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.LHS), ',', ...
                matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.RHS)];
        else
            code = '[],[]';
        end
        end
    end
end
