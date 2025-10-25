classdef Fzero < matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fzero(State)
    % constructs an Fzero object with the specified State property
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fzero(State)
        
        % Set solver name
        name = 'fzero';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(State, name, ...
            solverMiscInputs);
        
        % Set InitialPoint FilterVariablesFcn, Tooltip, and DisplayLabelTooltip
        obj.InitialPoint.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getFzeroInitialPointFilter();
        obj.InitialPoint.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'FzeroInitialPointTooltip');
        obj.InitialPoint.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'fzeroInitialPoint');
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'scalarEqObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'fzeroObjectiveFcn');
        end
    end
end
