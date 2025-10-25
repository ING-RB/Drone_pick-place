function SelectedVariableIndices = validateSelectedVariableIndices(opts, ...
                                                                   SelectedVariableIndices)
%validateSelectedVariableIndices   Verifies that SelectedVariableIndices is in
%   the correct range for the input TableBuilderOptions object OPTS.
%
%   Also throws an error if there are any duplicate
%   SelectedVariableIndices.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts                    (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
        SelectedVariableIndices (1, :) double {matlab.io.internal.common.builder.TableBuilder.mustBeValidIndices}
    end

    % Check that SelectedVariableIndices are all in valid
    % ranges.
    maxExpected = numel(opts.VariableNames);
    maxActual   = max(SelectedVariableIndices, [], "all");
    if maxActual > maxExpected
        error(message("MATLAB:io:common:builder:SelectedVariableIndicesTooLarge", maxExpected));
    end

    % Check uniqueness of SelectedVariableIndices.
    % Currently they must be unique. The repeated case has not been
    % implemented.
    assert(opts.RequireUniqueSelectedVariableIndices);
    numExpected = numel(SelectedVariableIndices);
    numActual = numel(unique(SelectedVariableIndices));
    if numActual ~= numExpected
        error(message("MATLAB:io:common:builder:SelectedVariableIndicesMustBeUnique"));
    end

    % Validate that the new indices don't accidentally deselect a constrained
    % variable name for RowFilter.
    import matlab.io.internal.common.builder.TableBuilder.checkRowFilterConstrainedVariableNamesSelection
    SelectedVariableIndices = checkRowFilterConstrainedVariableNamesSelection(opts, SelectedVariableIndices);
end