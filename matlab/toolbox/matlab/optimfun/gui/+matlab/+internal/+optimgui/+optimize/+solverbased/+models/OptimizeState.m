classdef OptimizeState < matlab.internal.optimgui.optimize.models.AbstractTaskState
    % The OptimizeState class holds the current state of the Optimize LET.
    % On construction, it assigns default values for its properties.
    %
    % See also matlab.internal.optimgui.optimize.OptimizeConstants, matlab.internal.optimgui.optimize.Optimize

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (Access = public)

        % Track version history
        Version = matlab.internal.optimgui.optimize.solverbased.models.OptimizeState.getLatestVersionNumber();

        % Optimize model
        ObjectiveType (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultObjectiveType;
        ConstraintType (1, :) cell = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultConstraintType;
        SolverName (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultSolverName;

        % Objective function solver input
        ObjectiveFcn (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultFcnParse;

        % Solver misc. inputs
        InitialPoint (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        LinearObjective (1, :) char  = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        Goal (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        Weight (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        NumberOfVariables (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        QuadraticObjective (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        InputData (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        OutputData (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        LLSMat (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        LLSVec (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;

        % Constraint solver inputs
        LowerBounds (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultLowerBounds;
        UpperBounds (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultUpperBounds;
        LinearInequality (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultLinearConstraint;
        LinearEquality (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultLinearConstraint;
        NonlinearConstraintFcn (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultFcnParse;
        IntegerConstraint (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;
        SecondOrderCone (1, :) char = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue;

        % Options model
        Options (1, 1) struct = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultOptionsStruct;
    end

    methods (Access = protected)

        function state = updateStateStruct(this, state)

            % Version 4 updates. Check for the "UnsetFromFileFcn" field in
            % function structs ObjectiveFcn and NonlinearConstraintFcn
            state.ObjectiveFcn = i_checkUnsetFromFileFcn(state.ObjectiveFcn);
            state.NonlinearConstraintFcn = i_checkUnsetFromFileFcn(state.NonlinearConstraintFcn);

            % Call superclass method
            state = updateStateStruct@matlab.internal.optimgui.optimize.models.AbstractTaskState(this, state);
        end
    end

    methods (Static, Access = public)

        function ver = getLatestVersionNumber()

            % Iterate version number as the state is updated

            % Version 2 (21a): For 20b forward compatibility, "WorkspaceValue" field
            % of LowerBounds and UpperBounds is set to a non-scalar when specifying
            % from workspace.

            % Version 3 (22a): When updating from a previous state struct, loop over property
            % names and assign corresponding fieldname.

            % Version 4 (25a): "UnsetFromFileFcn" field added to function structs
            % to account for locale variations.
            ver = 4;
        end
    end
end

function fcnStruct = i_checkUnsetFromFileFcn(fcnStruct)

    % Check whether the current function name needs to reset for the current locale.
    if strcmp(fcnStruct.Source, 'FromFile') && isfield(fcnStruct, 'UnsetFromFileFcn') && strcmp(fcnStruct.Name, fcnStruct.UnsetFromFileFcn)
        fcnStruct.Name = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn;
    end

    % Always reset the "UnsetFromFileFcn" field with the current locale
    fcnStruct.UnsetFromFileFcn = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn;
end
