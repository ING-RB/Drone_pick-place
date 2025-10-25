classdef Quadprog < matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Quadprog(State)
    % constructs an Quadprog object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        QuadraticObjective matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        LinearObjective matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Quadprog(State)
        
        % Set solver name
        name = 'quadprog';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'QuadraticObjective', 'LinearObjective'};
        solverMiscInputsOptional = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver(State, name, ...
            solverMiscInputs, solverMiscInputsOptional);
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'LinearObjective';
        obj.UpperBounds.ScalarMatch = 'LinearObjective';
        
        % Set LinearObjective label tooltip
        obj.LinearObjective.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'quadprogLinearObjective');
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:quadprogSummary', ...
            ['`', obj.QuadraticObjective.Value, '`'], ['`', obj.LinearObjective.Value, '`']));
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)

        % For some algorithms, the optional inputs become required
        if ~strcmp(obj.Options.OptimOptions.Algorithm, 'interior-point-convex')
            value = [obj.SolverMiscInputs, obj.SolverMiscInputsOptional, obj.SelectedConstraintNames];
        else
            value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        end
        end
    end
end
