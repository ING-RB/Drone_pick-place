classdef Surrogateopt < matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Surrogateopt(State)
    % constructs an Surrogateopt object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        IntegerConstraint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
        % Not required for calling solver, but necessary for expanding scalar bounds
        NumberOfVariables matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Surrogateopt(State)
        
        % Set solver name
        name = 'surrogateopt';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'NumberOfVariables'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Create IntegerConstraint property
        obj.IntegerConstraint = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'IntegerConstraint');
        
        % Set solver constraints cell array. Constraints order is different 
        % compared to other nonlinear constrained solvers
        obj.Constraints = {'LowerBounds', 'UpperBounds', 'IntegerConstraint', ...
            'LinearInequality', 'LinearEquality', 'NonlinearConstraintFcn', 'SecondOrderCone'};
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'NumberOfVariables';
        obj.UpperBounds.ScalarMatch = 'NumberOfVariables';
        
        % Same message to display when user adds NonlinearConstraintFcn or SecondOrderCone
        obj.NonlinearConstraintFcn.WidgetProperties.Message = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'surrogateoptNonlinearConstraintFcn');
        obj.SecondOrderCone.WidgetProperties.Message = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'surrogateoptNonlinearConstraintFcn');
        
        % Set NonlinearConstraintFcn doc link ID
        obj.NonlinearConstraintFcn.WidgetProperties.DocLinkID = 'surrogateObj';
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'surrogateObj');
        end
        
        function [code, anonymousConFcnCode, anonymousConFcnClear] = generateConstraintInputsCode(obj)
        
        % Override superclass method
        
        % surrogateopt does not have a NonlinearConstraintFcn input property.
        % On the view side, a message is provided telling the user to input the
        % fcn with their objective fcn
        
        % Nonlinear constraint function code
        anonymousConFcnCode = '';
        anonymousConFcnClear = '';
        
        % Generate code for constraints, remove NonlinearConstraintFcn and SecondOrderCone
        code = obj.generateInputsCode(setdiff(obj.Constraints, {'NonlinearConstraintFcn', 'SecondOrderCone'}, 'stable'));
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % Call superclass method
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        
        % Lower and upper bounds are required for this solver
        value = unique([value, {'LowerBounds', 'UpperBounds'}], 'stable');
        
        % Second-order cone constraints need to be specified as part of the
        % nonlinear constraints. However, NonlinearConstraintFcn needs to be specified
        % as part of the objective fcn. Don't make either constraint required for
        % generating code
        value = setdiff(value, {'NonlinearConstraintFcn', 'SecondOrderCone'}, 'stable');
        end
        
        function value = getConstraintsRequiredMessage(obj)
        
        % If both bounds constraints are not selected, pull message from catalog.
        % Else, return empty char
        if ~all(ismember({'LowerBounds', 'UpperBounds'}, obj.SelectedConstraintNames))
            value = getString(message('MATLAB:optimfun_gui:Labels:BoundsConstraintsRequired', obj.Name));
        else
            value = '';
        end
        end
        
        function code = generateInputsCode(obj, inputList)
        
        % Extend superclass method
        
        % surrogateopt syntax does not take a NumberOfVariables input. It is only part
        % of the LET for expanding scalar bounds. If inputList contains NumberOfVariables
        % return empty char
        % Else, call superclass method
        if ismember('NumberOfVariables', inputList)
            code = '';
        else
            code = generateInputsCode@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(obj, inputList);
        end
        end
    end
end
