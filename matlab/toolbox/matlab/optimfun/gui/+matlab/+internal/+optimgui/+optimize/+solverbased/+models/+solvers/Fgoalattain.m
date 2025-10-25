classdef Fgoalattain < matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fgoalattain(State) 
    % constructs a Fgoalattain object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        Goal matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        Weight matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fgoalattain(State)
        
        % Set solver name
        name = 'fgoalattain';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint', 'Goal', 'Weight'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'multiObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'fgoalattainObjectiveFcn');
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:fgoalattainSummary', ...
            ['`', obj.ObjectiveFcn.Value.Name, '`'], ['`', obj.Goal.Value, '`']));
        end
    end
end
