classdef (Abstract) ConstrainedSolver < matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    % The ConstrainedSolver Abstract class defines common properties and methods
    % for constrained Optimize LET model classes
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Dependent, GetAccess = public, SetAccess = protected)
        
        % cellstr of solver's viewed constraints in the order they appear
        % in the view
        SelectedConstraintNames (1, :) cell
        
        % For most solvers, constraints are not required. However, when constraints
        % are required, we want to provide a message to users in the UI about it.
        % This dependent property returns empty or pulls a message from the catalog
        ConstraintsRequiredMessage (1, :) char
    end
    
    % Get methods
    methods
        
        function value = get.SelectedConstraintNames(obj)
        % All selected constraints are synced with state's ConstraintType property.
        % Return intersection with this solver's constraints
        value = intersect(reshape(obj.State.ConstraintType, 1, []), obj.Constraints, 'stable');
        end
        
        function value = get.ConstraintsRequiredMessage(obj)
        
        % Call protected method so that subclasses can override this get method
        value = obj.getConstraintsRequiredMessage();
        end
    end
    
    methods (Access = public)
        
        function obj = ConstrainedSolver(State, varargin)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(State, varargin{:})
        end
        
        function [code, anonymousConFcnCode, anonymousConFcnClear] = generateConstraintInputsCode(obj)
        
        % Called by the SolverModel class when generating code
        
        % Most solver's don't have a NonlinearConstraintFcn. Default to no anonymous fcn code
        % here and let subclasses override
        anonymousConFcnCode = '';
        anonymousConFcnClear = '';
        
        % Generate code for constraint inputs
        code = obj.generateInputsCode(obj.Constraints);
        end
    end
    
    methods (Access = protected)
        
        function value = getRequiredInputs(obj)
        
        % Call superclass method
        value = getRequiredInputs@matlab.internal.optimgui.optimize.solverbased.models.SolverModel(obj);
        
        % Extend required inputs with selected constraints
        value = [value, obj.SelectedConstraintNames];
        end
        
        function value = getConstraintsRequiredMessage(~)
        
        % For most solvers, constraints are not required. Return an empty char
        value = '';
        end
    end
end
