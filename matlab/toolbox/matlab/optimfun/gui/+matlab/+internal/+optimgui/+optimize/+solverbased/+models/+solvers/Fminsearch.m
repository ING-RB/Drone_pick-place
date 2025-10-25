classdef Fminsearch < matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fminsearch(State)
    % constructs an Fminsearch object with the specified State property.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fminsearch(State)
        
        % Set solver name
        name = 'fminsearch';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input and doc link ID
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'singleObj');
        obj.ObjectiveFcn.WidgetProperties.DocLinkID = 'fminsearchObj';
        end
    end
end
