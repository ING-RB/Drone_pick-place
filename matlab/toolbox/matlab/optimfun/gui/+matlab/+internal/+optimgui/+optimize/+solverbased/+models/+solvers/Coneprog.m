classdef Coneprog < matlab.internal.optimgui.optimize.solverbased.models.solvers.Linprog
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Coneprog(State)
    % constructs a Coneprog object with the specified State property
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        SecondOrderCone matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Coneprog(State)
        
        % Set solver name
        name = 'coneprog';
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.solvers.Linprog(State, name);
        
        % Create constraint property and set widget message to empty
        obj.SecondOrderCone = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'SecondOrderCone');
        obj.SecondOrderCone.WidgetProperties.Message = '';
        
        % Append solver constraints cell array
        obj.Constraints = ['SecondOrderCone', obj.Constraints];
        end
        
        function [tf, whatsMissing] = isSet(obj)
        
        % Call SolverModel method, don't use direct superclass Linprog's method
        [tf, whatsMissing] = isSet@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(obj);
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % Call superclass method
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        
        % SecondOrderCone constraint is required for this solver
        value = unique([value, 'SecondOrderCone'], 'stable');
        end
        
        function value = getConstraintsRequiredMessage(obj)
        
        % If SecondOrderCone constraint is not selected, pull message from catalog.
        % Else, return empty char
        if ~any(strcmp(obj.SelectedConstraintNames, 'SecondOrderCone'))
            value = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'coneprogConstraintRequired');
        else
            value = '';
        end
        end
    end
end
