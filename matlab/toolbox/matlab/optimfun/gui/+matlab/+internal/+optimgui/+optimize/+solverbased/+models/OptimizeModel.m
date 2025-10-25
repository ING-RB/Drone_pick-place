classdef OptimizeModel < matlab.internal.optimgui.optimize.models.AbstractTaskModel
    % obj = matlab.internal.optimgui.optimize.solverbased.models.OptimizeModel() constructs an OptimizeModel
    % object to be viewed by the Optimize LET

    % Copyright 2020-2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)

        % Map serves as a lookup for valid solvers given the ObjectiveType
        % and ConstraintType properties
        SolverTypeMap matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap

        % Solver specific information to set and view
        SolverModel % Solver class, example matlab.internal.optimgui.optimize.model.solvers.Fmincon

        % This property stores whether the user has a license for the specified
        % problem type
        hasLicense (1, 1) logical = true;
    end

    properties (Dependent, SetObservable, AbortSet, Access = public)

        % Specified using state buttons. No buttons selected sets this
        % property to Unsure
        ObjectiveType (1, :) char

        % Specified using state buttons. Users can specify multiple constraints
        % except if the None (Unconstrained) button is selected. No buttons
        % selected sets this property to Unsure
        ConstraintType cell

        % Active solver for the task
        SolverName (1, :) char
    end

    properties (Dependent, GetAccess = public)

        % List of valid solvers for the ObjectiveType and ConstraintType
        % combination. Pulled from SolverTypeMap property
        SolverList cell

        % Conversational description of the solver is appended to the solver name.
        % This is what users will see in the dropdown
        SolverListMessage cell
    end

    % Set/get methods
    methods

        function set.ObjectiveType(obj, value)
        obj.State.ObjectiveType = value; % View listening, calls app.SolverListChanged
        end

        function value = get.ObjectiveType(obj)
        value = obj.State.ObjectiveType;
        end

        function set.ConstraintType(obj, value)
        obj.State.ConstraintType = value; % View listening, calls app.SolverListChanged
        end

        function value = get.ConstraintType(obj)
        value = obj.State.ConstraintType;
        end

        function set.SolverName(obj, value)
        obj.State.SolverName = value; % View listening, calls app.SolverNameChanged
        end

        function value = get.SolverName(obj)
        value = obj.State.SolverName;
        end

        function value = get.SolverList(obj)
        value = obj.SolverTypeMap(obj.ObjectiveType, obj.ConstraintType);
        end

        function value = get.SolverListMessage(obj)
        % If the solver list is a license message, there's nothing to append
        if contains(obj.SolverList, 'unlicensed')
            value = matlab.internal.optimgui.optimize.utils.getMessage('Labels', obj.SolverList);
        else
            conversational = matlab.internal.optimgui.optimize.utils.getMessage('Labels', obj.SolverList);
            delim = cell(size(conversational));
            delim(:) = {'-'};
            value = join([obj.SolverList, delim, conversational]);
            % Indicate the first item is recommended
            value{1} = [value{1}, blanks(1), ...
                matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'recommendedSolver')];
        end
        end
    end

    methods (Access = public)

        function obj = OptimizeModel()

        % Create SolverTypeMap
        obj.SolverTypeMap = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap;

        % Default state
        state = matlab.internal.optimgui.optimize.solverbased.models.OptimizeState();

        % Check that the current SolverName is valid, depending on the user's license
        % it may not be. If it's not, set the SolverName to the first item of the
        % SolverTypeMap's masterList
        if ~any(strcmp(state.SolverName, obj.SolverTypeMap.masterList))
            state.SolverName = obj.SolverTypeMap.masterList{1};
        end

        % Update State property
        obj.updateModel(state);
        end

        function updateModel(obj, state)

        % Called by this constructor and setState method of the Optimize class.
        % Updates the State and SolverModel properties

        % Set State reference
        obj.State = state;

        % Update solver model
        obj.updateSolverModel();
        end

        function updateSolverModel(obj)

        % Called by the updateState method and the SolverNameChanged method
        % of the Optimize class.

        % Set SolverModel and hasLicense properties
        if contains(obj.SolverName, 'unlicensed')
            obj.hasLicense = false;
        else
            obj.hasLicense = true;
            obj.SolverModel = matlab.internal.optimgui.optimize.solverbased.models.SolverModel.createSolverModel(...
                obj.SolverName, obj.State);
        end
        end

        function tf = isSet(~)

        % We always consider this model to be set. The summary and
        % generated code typically depend on if/how the SolverModel
        % property is set
        tf = true;
        end

        function summary = generateSummary(obj)

        % If the user has a license for the specified problem type AND sufficient
        % inputs are specified to solve the problem, generate summary
        % Else, show the unset summary
        if obj.hasLicense && obj.SolverModel.isSet()
            summary = obj.SolverModel.generateSummary();
        else
            summary = matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'unsetSummary');
        end
        end

        function [code, outputs] = generateCode(obj)

        % If the user has a license for the specified problem type proceed with
        % code generation for the SolverModel.
        % Else, there is no valid SolverModel. Show the toolbox required message as code.
        if obj.hasLicense
            % If sufficient inputs are specified to solve the problem, generate the code
            % Else, generate code listing missing required inputs
            [isSet, whatsMissing] = obj.SolverModel.isSet();
            if isSet
                [outputs, code] = obj.SolverModel.generateCode();
            else
                [outputs, code] = obj.SolverModel.generateWhatsMissingCode(whatsMissing);
            end
        else
            outputs = {};
            code = ['disp(''', matlab.internal.optimgui.optimize.utils.getMessage('Labels', ...
                obj.SolverName), ''')'];
        end
        end
    end
end
