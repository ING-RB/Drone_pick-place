classdef Fminunc < matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fminunc(State)
    % constructs an Fminunc object with the specified State property.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fminunc(State)
        
        % Set solver name
        name = 'fminunc';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'singleObj');
        end
    end
end
