classdef Intlinprog < matlab.internal.optimgui.optimize.solverbased.models.solvers.Linprog
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Intlinprog(State)
    % constructs an Intlinprog object with the specified State property
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        IntegerConstraint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Intlinprog(State)
        
        % Set solver name
        name = 'intlinprog';
        
        % Set order of solver's miscellaneous input
        solverMiscInputsOptional = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.solvers.Linprog(State, name, ...
            solverMiscInputsOptional);
        
        % Create constraint property
        obj.IntegerConstraint = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'IntegerConstraint');
        obj.IntegerConstraint.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getIntegerConstraintFilter();
        obj.IntegerConstraint.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'IntegerConstraintTooltip');
        
        % Append solver constraints cell array
        obj.Constraints = ['IntegerConstraint', obj.Constraints];
        end
    end
    
    methods (Access = protected)
        
        function value = getConstraintsRequiredMessage(obj)
        
        % If no contraints aside from IntegerConstraint is selected, pull message from catalog.
        % Else, return empty char
        if isempty(setdiff(obj.SelectedConstraintNames, 'IntegerConstraint'))
            value = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'intlinprogAtLeastOneConstraintRequired');
        else
            value = '';
        end
        end
    end
end
