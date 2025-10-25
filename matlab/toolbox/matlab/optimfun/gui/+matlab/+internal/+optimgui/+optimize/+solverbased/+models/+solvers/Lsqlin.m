classdef Lsqlin < matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Lsqlin(State)
    % constructs an Lsqlin object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        LLSMat matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        LLSVec matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Lsqlin(State)
        
        % Set solver name
        name = 'lsqlin';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'LLSMat', 'LLSVec'};
        solverMiscInputsOptional = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver(State, name, ...
            solverMiscInputs, solverMiscInputsOptional);
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'LLSMat';
        obj.UpperBounds.ScalarMatch = 'LLSMat';
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:llsSummary', ...
            ['`', obj.LLSMat.Value, '`'], ['`', obj.LLSVec.Value, '`'], ...
            ['`', obj.Name, '`']));
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % For some algorithms, the optional inputs become required
        if ~strcmp(obj.Options.OptimOptions.Algorithm, 'interior-point')
            value = [obj.SolverMiscInputs, obj.SolverMiscInputsOptional, obj.SelectedConstraintNames];
        else
            value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        end
        end
    end
end
