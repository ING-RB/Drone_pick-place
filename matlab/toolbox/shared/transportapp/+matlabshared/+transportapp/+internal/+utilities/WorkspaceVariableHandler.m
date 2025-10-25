classdef WorkspaceVariableHandler < matlabshared.mediator.internal.Publisher & ...
        internal.matlab.datatoolsservices.WorkspaceListener
    %WORKSPACEVARIABLEHANDLER class manages all the MATLAB workspace
    % operations for shared transport app, namely -
    % 1. Getting all MATLAB workspace variables.
    % 2. Receiving and handling any updates made to the MATLAB base
    %    workspace.
    % 3. Parsing any MATLAB workspace variable to see if it is of the
    %    correct type to be used for the shared transportapp
    % 4. Creating and setting a base MATLAB workspace variable.

    % Copyright 2021 The MathWorks, Inc.

    properties (SetObservable)
        % Contains info about the MATLAB base workspace variable names that
        % changed, and the kind of event associated with these variable
        % names.
        WorkspaceUpdated matlabshared.transportapp.internal.utilities.forms.WorkspaceUpdateInfo = ...
            matlabshared.transportapp.internal.utilities.forms.WorkspaceUpdateInfo.empty
    end

    %% Lifetime
    methods
        function obj = WorkspaceVariableHandler(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
        end
    end

    %% Implementing abstract methods from internal.matlab.datatoolsservices.WorkspaceListener
    methods
        function workspaceUpdated(obj, varNames, eventName)
            % Gets invoked whenever there is a change in the MATLAB
            % Workspace Variable list.

            if isequal(varNames, {'ans'})
                % try to evaluate ans and see if ans is a valid variable.
                % g2166233: WorkspaceListener firing unexpected events with
                % {'ans'} as varNames.
                try
                    matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler.validateAns(string(varNames), eventName);
                catch
                    % Eval failed, that means ans is not a valid variable
                    % name.
                    return
                end
            end
            varNames = string(varNames);
            eventName = string(eventName);

            obj.WorkspaceUpdated = ...
                matlabshared.transportapp.internal.utilities.forms.WorkspaceUpdateInfo(varNames, eventName);
        end
    end

    %% Static Helper Functions
    methods (Static)
        function values = parse(variableNames)
            % Parse the entire list of variables from the MATLAB workspace
            % variable and return an array of WorkspaceVariableInfo that
            % contains the variable names and the evaluated type of that
            % variable.

            arguments
                variableNames (1, :) string
            end

            import matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler
            import matlabshared.transportapp.internal.utilities.forms.WorkspaceTypeEnum
            import matlabshared.transportapp.internal.utilities.forms.WorkspaceVariableInfo

            values = WorkspaceVariableInfo.empty;

            for var = variableNames
                try
                    workspaceVariable = evalin("base", var);
                catch
                    % Failed to evaluate the base variable. Move on to the
                    % next variable.
                    continue
                end

                % Check the "valid" type for each workspace variable.
                % "Valid" implies that these workspace variables are of the
                % correct type and format for use in shared transportapp.

                if WorkspaceVariableHandler.isValidNumeric(workspaceVariable)
                    type = WorkspaceTypeEnum.Numeric;
                elseif WorkspaceVariableHandler.isValidString(workspaceVariable)
                    type = WorkspaceTypeEnum.String;
                elseif WorkspaceVariableHandler.isValidChar(workspaceVariable)
                    type = WorkspaceTypeEnum.Char;
                else
                    type = WorkspaceTypeEnum.Other;
                end

                tempValue = WorkspaceVariableInfo(var, type);
                values = [values, tempValue]; %#ok<*AGROW>
            end
        end

        function variableNames = getWorkspaceVariableNames()
            % Get a list of all MATLAB Workspace Variables

            variableNames = evalin("base", "who");
            variableNames = string(variableNames)';
        end

        function setVariableInMatlabWorkspace(varName, value)
            % Save the the "varName" as a variable in the MATLAB base
            % workspace and assign the value "value" to it.

            assignin("base", varName, value);
        end
    end

    methods (Access = private, Static)
        function validateAns(val, eventName)
            % Validate that the "ans" variable event is a valid one.

            % This means that there was a valid "ans" in the MATLAB
            % workspace which got deleted. It is safe to relay this as a
            % valid Workspace Event
            if string(eventName) == "VARIABLE_DELETED"
                return
            end

            % If this errors, this means that there was a "fake" event from
            % the internal.matlab.datatoolsservices.WorkspaceListener
            % (g2166233).
            val = evalin("base", val); %#ok<NASGU>
        end

        function flag = isValidNumeric(value)
            % The value needs to be a numeric value of size either 1xn or
            % mx1.

            [numRows, numColumns] = size(value);
            flag = isnumeric(value) ...
                && ~isempty(value) ...
                && isreal(value) ...
                && ~(numRows > 1 && numColumns > 1);
        end

        function flag = isValidString(value)
            % The value needs to be a 1x1 string.

            flag = isstring(value) && length(value) == 1;
        end

        function flag = isValidChar(value)
            % The value needs to be a 1xn char array.

            [numRows, ~] = size(value);
            flag = ischar(value) && numRows == 1;
        end
    end
end