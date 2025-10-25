classdef (Abstract) LinearConstrainedSolver < matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver
    % The LinearConstrainedSolver Abstract class defines common properties
    % for linear constrained Optimize LET solver model classes
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Access = public)
        
        LinearInequality matlab.internal.optimgui.optimize.solverbased.models.inputs.LinearConstraintInput
        LinearEquality matlab.internal.optimgui.optimize.solverbased.models.inputs.LinearConstraintInput
    end
    
    methods (Access = public)
        
        function obj = LinearConstrainedSolver(State, varargin)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.BoundsConstrainedSolver(State, varargin{:})
        
        % Create constraint properties
        obj.LinearInequality = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'LinearInequality');
        obj.LinearEquality = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'LinearEquality');
        
        % Append solver constraints cell array
        obj.Constraints = ['LinearInequality', 'LinearEquality', obj.Constraints];
        end
    end
end
