classdef Linprog < matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Linprog(State)
    % constructs an Linprog object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        LinearObjective matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
    end
    
    methods (Access = public)
        
        function obj = Linprog(State, varargin)
        
        % Set solver name
        name = 'linprog';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'LinearObjective'};
        solverMiscInputsOptional = cell(0);
        
        % If a subclass passed arguments to the constructor, pass on to superclass
        if numel(varargin) > 0
            name = varargin{1};
            if numel(varargin) > 1
                solverMiscInputsOptional = varargin{2};
            end
        end
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.LinearConstrainedSolver(State, name, ...
            solverMiscInputs, solverMiscInputsOptional);
        
        % Set bounds scalar expansion match variable
        obj.LowerBounds.ScalarMatch = 'LinearObjective';
        obj.UpperBounds.ScalarMatch = 'LinearObjective';
        end
        
        function [tf, whatsMissing] = isSet(obj)
        
        % Call superclass method
        [tf, whatsMissing] = isSet@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(obj);
        
        % Check whether at least one constraint is set
        % Include setdiff with IntegerConstraint for subclass Inltinprog
        if ~obj.isInputsListSet(setdiff(obj.Constraints, 'IntegerConstraint'), 'any')
            tf = false;
            whatsMissing = [whatsMissing, lower(matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', [obj.Name, 'AtLeastOneConstraintRequired']))];
        end
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:linprogSummary', ...
            ['`', obj.LinearObjective.Value, '`'], ['`', obj.Name, '`']));
        end
    end
    
    methods (Access = protected)
        
        function value = getConstraintsRequiredMessage(obj)
        
        % If no contraints are selected for this solver, pull message from catalog.
        % Else, return empty char
        if isempty(obj.SelectedConstraintNames)
            value = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'linprogAtLeastOneConstraintRequired');
        else
            value = '';
        end
        end
    end
end
