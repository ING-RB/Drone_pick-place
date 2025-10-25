classdef Particleswarm < matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Particleswarm(State)
    % constructs an Particleswarm object with the specified State property
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        NumberOfVariables matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Particleswarm(State)
        
        % Set solver name
        name = 'particleswarm';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'NumberOfVariables'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'NumberOfVariables';
        obj.UpperBounds.ScalarMatch = 'NumberOfVariables';
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'singleObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'nvarsObjectiveFcn');
        end
    end
end
