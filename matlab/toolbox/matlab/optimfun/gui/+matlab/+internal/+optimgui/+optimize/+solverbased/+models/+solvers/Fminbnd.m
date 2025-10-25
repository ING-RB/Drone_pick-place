classdef Fminbnd < matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Fminbnd(State)
    % constructs an Fminbnd object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Fminbnd(State)
        
        % Set solver name
        name = 'fminbnd';
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver(State, name);
        
        % Set bounds FilterVariablesFcn and Tooltip
        obj.LowerBounds.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getScalarFilter();
        obj.UpperBounds.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getScalarFilter();
        obj.LowerBounds.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'ScalarTooltip');
        obj.UpperBounds.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'ScalarTooltip');
        
        % Set bounds scalar expansion match variable. Bounds are already scalar, no need to expand
        obj.LowerBounds.ScalarMatch = '';
        obj.UpperBounds.ScalarMatch = '';
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'scalarFcnObj');
        
        % Set ObjectiveFcn label tooltip. fminbnd doesn't have a start point
        % so borrow tooltip used for solvers with nvars
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'nvarsObjectiveFcn');
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % Call superclass method
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        
        % Lower and upper bounds are required for this solver
        value = unique([value, {'LowerBounds', 'UpperBounds'}], 'stable');
        end
        
        function value = getConstraintsRequiredMessage(obj)
        
        % If both bounds constraints are set, pull message from catalog.
        % Else, return empty char
        if ~all(ismember({'LowerBounds', 'UpperBounds'}, obj.SelectedConstraintNames))
            value = getString(message('MATLAB:optimfun_gui:Labels:BoundsConstraintsRequired', obj.Name));
        else
            value = '';
        end
        end
    end
end
