classdef Lsqcurvefit < matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver
    % obj = matlab.internal.optimgui.optimize.solverbased.models.solver.Lsqcurvefit(State)
    % constructs an Lsqcurvefit object with the specified State property
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = ?matlab.internal.optimgui.optimize.solverbased.models.SolverModel)
        
        % Solver input properties
        InitialPoint matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        InputData matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        OutputData matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput
        ObjectiveFcn matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput
    end
    
    methods (Access = public)
        
        function obj = Lsqcurvefit(State)
        
        % Set solver name
        name = 'lsqcurvefit';
        
        % Set order of solver's miscellaneous input
        solverMiscInputs = {'InitialPoint', 'InputData', 'OutputData'};
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.NonlinearConstrainedSolver(State, name, ...
            solverMiscInputs);
        
        % Create ObjectiveFcn input
        obj.ObjectiveFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, 'lsqCfObj');
        
        % Set ObjectiveFcn label tooltip
        obj.ObjectiveFcn.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Tooltips', 'lsqcurvefitObjectiveFcn');
        
        % Set ObjectiveFcn widget NumberOfArgsThresh
        obj.ObjectiveFcn.WidgetProperties.NumberOfArgsThresh = 2;

        % Update cellstr of constraints in the order required by the solver syntax.
        % For this solver, bounds must be moved to the front
        boundConstraintNames = {'LowerBounds', 'UpperBounds'};
        obj.Constraints = [boundConstraintNames, setdiff(obj.Constraints, boundConstraintNames, 'stable')];
        end
        
        function [solverObjFcnCode, anonymousObjFcnCode, anonymousObjFcnClear] = generateObjectiveFcnCode(obj)
        
        % Override superclass method in SolverModel.m
        
        % Generate function input code pieces
        [solverObjFcnCode, anonymousObjFcnCode, anonymousObjFcnClear] = obj.ObjectiveFcn.generateCode();
        solverObjFcnCode = [solverObjFcnCode, ','];
        
        % If the anonymousObjFcnCode is not empty, find the starting index
        % of the function name and add 'xdata' as second anonymous function input
        if ~isempty(anonymousObjFcnCode)
            ind = strfind(anonymousObjFcnCode, ...
                matlab.internal.optimgui.optimize.utils.addBackTicks(obj.ObjectiveFcn.Value.Name));
            anonymousObjFcnCode = [anonymousObjFcnCode(1:ind - 2), ...
                [',', matlab.internal.optimgui.optimize.utils.addBackTicks('xdata')], ...
                anonymousObjFcnCode(ind - 1:end)];
        end
        end
        
        function summary = generateSummary(obj)
        
        % Override superclass method
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:lsqcurvefitSummary', ...
            ['`', obj.ObjectiveFcn.Value.Name, '`'], ['`', obj.OutputData.Value, '`']));
        end
    end
end
