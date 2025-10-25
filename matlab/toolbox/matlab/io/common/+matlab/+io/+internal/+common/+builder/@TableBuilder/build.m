function T = build(obj, varargin)
%TableBuilder.build   Construct a table from the current TableBuilder options.
%
%   The number of variables provided as input must match the number of VariableNames
%   in the TableBuilder object.

%   Copyright 2022 The MathWorks, Inc.

    % The number of variables passed in must match the number of variable names in
    % the TableBuilder.
    Nexpected = numel(obj.VariableNames);
    Nactual = numel(varargin);
    if Nexpected ~= Nactual
        msgid = "MATLAB:io:common:builder:IncorrectNumberOfVariablesForBuild";
        error(message(msgid, "build", "VariableNames", Nactual, Nexpected));
    end

    % Verify that the heights of all input variables are consistent.
    import matlab.io.internal.common.builder.TableBuilder.validateConsistentVariableHeights
    validateConsistentVariableHeights(varargin{:});

    % Perform the type check if there are nonmissing VariableTypes.
    import matlab.io.internal.common.builder.TableBuilder.checkVariableTypes
    checkVariableTypes(obj.Options, false, varargin{:});

    % Call into buildSelected() to generate the final table.
    T = obj.buildSelected(varargin{obj.SelectedVariableIndices});
end
