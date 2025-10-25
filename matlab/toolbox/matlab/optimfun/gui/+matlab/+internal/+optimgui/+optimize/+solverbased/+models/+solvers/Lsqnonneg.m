classdef Lsqnonneg < matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Lsqnonneg(State)
    % constructs an Lsqnonneg object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        LLSMat matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        LLSVec matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        LowerBounds matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput
    end
    
    methods (Access = public)
        
        function obj = Lsqnonneg(State)
        
        % Set solver name
        name = 'lsqnonneg';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'LLSMat', 'LLSVec'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Create constraint properties
        obj.LowerBounds = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'LowerBounds');
        
        % Append solver constraints cell array
        obj.Constraints = [obj.Constraints, 'LowerBounds'];
        
        % Message to display when user adds LowerBounds
        obj.LowerBounds.WidgetProperties.Message = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'lsqnonnegLowerBounds');
        end
        
        function [code, anonymousConFcnCode, anonymousConFcnClear] = generateConstraintInputsCode(~)
        
        % Override superclass method
        % lsqnonneg solver syntax does not require specifying the implicit LowerBoundsConstraint
        code = '';
        anonymousConFcnCode = '';
        anonymousConFcnClear = '';
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
        
        % Don't call direct superclass because the LowerBounds constraint isn't 
        % actually required here. Call SolverModel class method instead.
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(obj);
        end
    end
end
