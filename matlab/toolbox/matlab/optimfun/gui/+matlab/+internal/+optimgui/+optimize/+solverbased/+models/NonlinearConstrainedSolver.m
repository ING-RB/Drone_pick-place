classdef (Abstract) NonlinearConstrainedSolver < matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver
    % The NonlinearConstrainedSolver Abstract class defines common properties
    % for nonlinear constrained Optimize LET solver model classes
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Access = public)
        
        NonlinearConstraintFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
        % Second order cone constraints can be input as part of the nonlinear constraint function.
        % Include this input for all nonlinear constrained solvers to provide a message to users
        SecondOrderCone matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = NonlinearConstrainedSolver(State, varargin)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver(State, varargin{:})
        
        % Create constraint property
        obj.NonlinearConstraintFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'nonlConstr');
        
        % Create second-order cone input to display message when users add constraint
        obj.SecondOrderCone = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'SecondOrderCone');
        obj.SecondOrderCone.WidgetProperties.Message = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'nonlinearConstrainedSolverConicConstraints');
        
        % Append solver constraints cell array
        obj.Constraints = [obj.Constraints, {'NonlinearConstraintFcn', 'SecondOrderCone'}];
        end
        
        function [code, anonymousConFcnCode, anonymousConFcnClear] = generateConstraintInputsCode(obj)
        
        % Override superclass ConstrainedSolver method
        
        % Generate NonlinearConstraintFcn code pieces. Use ~ here for the piece of code 
        % that goes into the solver's call syntax because that is accounted for
        % by the generateInputsCode method below
        [~, anonymousConFcnCode, anonymousConFcnClear] = obj.NonlinearConstraintFcn.generateCode();
        
        % Generate code for constraint inputs. These solver's don't actually have a SecondOrderCone constraint
        code = obj.generateInputsCode(setdiff(obj.Constraints, 'SecondOrderCone', 'stable'));
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % Call superclass method
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(obj);
        
        % Remove second-order cone constraints and replace it with NonlinearConstraintFcn
        % This is, if the user selects SecondOrderCone, we require NonlinearConstraintFcn
        value = unique(strrep(value, 'SecondOrderCone', 'NonlinearConstraintFcn'), 'stable');
        end
    end
end
