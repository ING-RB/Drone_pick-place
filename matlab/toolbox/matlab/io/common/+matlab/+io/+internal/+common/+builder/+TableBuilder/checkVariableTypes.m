function checkVariableTypes(opts, useSelectedVariables, varargin)
%checkVariableTypes   Verifies inputs are of the types
%   listed in VariableTypes.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
        useSelectedVariables (1, 1) logical
    end

    arguments (Repeating)
        varargin
    end

    if useSelectedVariables
        varTypes = opts.VariableTypes(opts.SelectedVariableIndices);
    else
        varTypes = opts.VariableTypes;
    end

    % Sanity check to make sure that the number of inputs is correct.
    msg = "Incorrect number of inputs to checkVariableTypes().";
    assert(numel(varargin) == numel(varTypes), msg);

    % Get the indices of the nonmissing VariableTypes.
    typeCheckIndices = find(~ismissing(varTypes));

    % Iterate over variables that need type checking and error if there's a
    % mismatch.
    for index = 1:numel(typeCheckIndices)
        variableIndex = typeCheckIndices(index);

        % TODO: Maybe do an isa-check instead of an exact class match?
        expectedType = varTypes(variableIndex);
        actualType = string(class(varargin{variableIndex}));

        if expectedType ~= actualType
            % Map selected variable index back to variable index.
            if useSelectedVariables
                variableIndex = opts.SelectedVariableIndices(variableIndex);
            end

            % Type mismatch: Received value of type "string" for variable index 5 named "hello".
            % Expected value of type "double".
            msgid = "MATLAB:io:common:builder:TypeMismatch";
            variableName = opts.VariableNames(variableIndex);
            error(message(msgid, actualType, variableIndex, variableName, expectedType));
        end
    end
end
