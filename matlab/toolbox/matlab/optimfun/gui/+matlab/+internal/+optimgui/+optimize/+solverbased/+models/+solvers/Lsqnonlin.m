classdef Lsqnonlin < matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Lsqnonlin(State)
    % constructs an Lsqnonlin object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Lsqnonlin(State)
        
        % Set solver name
        name = 'lsqnonlin';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'nlsqObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'lsqnonlinObjectiveFcn');

        % Update cellstr of constraints in the order required by the solver syntax.
        % For this solver, bounds must be moved to the front
        boundConstraintNames = {'LowerBounds', 'UpperBounds'};
        obj.Constraints = [boundConstraintNames, setdiff(obj.Constraints, boundConstraintNames, 'stable')];
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:lsqnonlinSummary', ...
            ['`', obj.ObjectiveFcn.Value.Name, '`']));
        end
    end
end
