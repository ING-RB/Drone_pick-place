classdef (Abstract) BoundsConstrainedSolver < matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver
    % The BoundsConstrainedSolver Abstract class defines common properties
    % for bounds constrained Optimize LET solver model classes
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Access = public)
        
        LowerBounds matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput
        UpperBounds matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput
    end
    
    methods (Access = public)
        
        function obj = BoundsConstrainedSolver(State, varargin)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.ConstrainedSolver(State, varargin{:})
        
        % Create constraint properties
        obj.LowerBounds = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'LowerBounds');
        obj.UpperBounds = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'UpperBounds');
        
        % Append solver constraints cell array
        obj.Constraints = [obj.Constraints, 'LowerBounds', 'UpperBounds'];
        end
    end
end
