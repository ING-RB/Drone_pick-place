classdef Gamultiobj < matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Gamultiobj(State)
    % constructs an Gamultiobj object with the specified State property
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        NumberOfVariables matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        IntegerConstraint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput        
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Gamultiobj(State)
        
        % Set solver name
        name = 'gamultiobj';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'NumberOfVariables'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver(State, name, ...
            solverMiscInputs);
       
        % Create constraint property
        obj.IntegerConstraint = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'IntegerConstraint');
        
        % Append solver constraints cell array
        obj.Constraints = [obj.Constraints, 'IntegerConstraint'];
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'NumberOfVariables';
        obj.UpperBounds.ScalarMatch = 'NumberOfVariables';
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'multiObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'nvarsObjectiveFcn');
        end
    end
end
