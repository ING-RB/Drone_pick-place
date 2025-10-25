classdef Fsolve < matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fsolve(State)
    % constructs an Fsolve object with the specified State property.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fsolve(State)
        
        % Set solver name
        name = 'fsolve';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'fsolveObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'fsolveObjectiveFcn');
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:fsolveSummary', ...
            ['`', obj.ObjectiveFcn.Value.Name, '`']));
        end
    end
end
