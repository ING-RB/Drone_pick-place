function ttb = construct(ttb, tb, ttbOpts)
%TimetableBuilder.construct   Constructs a TimetableBuilder from args.
%
%   TTB must be a TimetableBuilder.
%   TB must be a TableBuilder.
%   ARGS must be an N-V struct.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        ttb  (1, 1) matlab.io.internal.common.builder.TimetableBuilder
        tb   (1, 1) matlab.io.internal.common.builder.TableBuilder
        ttbOpts (1, 1) struct
    end

    opts = matlab.io.internal.common.builder.TimetableBuilderOptions();

    opts.TableBuilder = tb;

    isRowTimesSupplied = numel(fieldnames(ttbOpts)) > 0;

    if isRowTimesSupplied
        opts = constructFromRowTimes(opts, ttbOpts);
    else
        % Try to infer the RowTimes variable from the first selected
        % datetime/duration variable in the TableBuilder.
        opts = constructFromVariableTypes(opts);
    end

    ttb.Options = opts;
end

function opts = constructFromRowTimes(opts, args)
    import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex

    if isfield(args, "OriginalRowTimesVariableName")
        opts.OriginalRowTimesVariableName = args.OriginalRowTimesVariableName;
    end

    % Do the normalized variable name next so that it overrides the
    % original variable name if both were specified.
    if isfield(args, "RowTimesVariableName")
        opts.RowTimesVariableName = args.RowTimesVariableName;
    end

    if isfield(args, "RowTimesVariableIndex")
        opts.RowTimesVariableIndex = validateRowTimesVariableIndex(opts, args.RowTimesVariableIndex);
    end

    % Do RowTimes last if it is supplied.
    if isfield(args, "RowTimes")
        opts.RowTimes = args.RowTimes;
    end
end

function opts = constructFromVariableTypes(opts)
    timeyVariables = matches(opts.TableBuilder.SelectedVariableTypes, ["datetime" "duration"]);

    index = find(timeyVariables, 1);

    if isempty(index)
        error(message("MATLAB:io:common:builder:CouldNotInferRowTimes"));
    end

    % Convert the selected variable index back to a full variable index.
    index = opts.TableBuilder.SelectedVariableIndices(index);

    % Just directly set the index since we've verified that it is the right
    % type and it is selected.
    opts.RowTimesVariableIndex = index;
end
