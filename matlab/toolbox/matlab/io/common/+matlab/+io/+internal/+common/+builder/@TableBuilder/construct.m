function tb = construct(args)
%TableBuilder.construct   Constructs a TableBuilder from TableBuilderOptions args.
%
%   ARGS must be an N-V struct.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        args (1, 1) struct
    end

    opts = matlab.io.internal.common.builder.TableBuilderOptions();

    % Utility to help set N-V pairs.
    function obj = setFieldIfSupplied(obj, fieldname)
        if isfield(args, fieldname)
            obj.(fieldname) = args.(fieldname);
        end
    end

    % First store the behavioral options so they can be applied
    % during construction.
    opts = setFieldIfSupplied(opts, "WarnOnNormalizationDuringSet");
    opts = setFieldIfSupplied(opts, "WarnOnNormalizationDuringBuild");
    opts = setFieldIfSupplied(opts, "RequireUniqueSelectedVariableIndices");
    opts = setFieldIfSupplied(opts, "SaveOriginalVariableNamesInVariableDescriptions");

    % Handle PreserveVariableNames and VariableNamingRule first since
    % they decide if warnings should appear later during construction or not.
    import matlab.io.internal.common.builder.TableBuilder.convertPreserveVariableNamesToVariableNamingRule
    if isfield(args, "PreserveVariableNames")
        opts.VariableNamingRule = convertPreserveVariableNamesToVariableNamingRule(args.PreserveVariableNames);
    end

    % Do VariableNamingRule after PreserveVariableNames so that it
    % overrides PreserveVariableNames if both are specified.
    opts = setFieldIfSupplied(opts, "VariableNamingRule");

    % Handle the VariableNames-related properties next. These will warn if
    % normalization needs to occur.
    opts = setFieldIfSupplied(opts, "OriginalVariableNames");

    if isfield(args, "VariableNames")
        % Setting VariableNames directly is a problem.
        % VariableNames is completely constrained once OriginalVariableNames and
        % VariableNamingRule is defined.
        % So a user shouldn't be allowed to modify VariableNames independently of
        % OriginalVariableNames. Therefore, any set() on VariableNames will also
        % update OriginalVariableNames. A warning will be shown later if this causes
        % name normalization to occur.
        opts.OriginalVariableNames = args.VariableNames;
    end

    % Default VariableTypes to missing string array of same length as VariableNames.
    opts.VariableTypes = repmat(string(missing), 1, numel(opts.OriginalVariableNames));

    % Cross-validate the VariableNames options and create the TableBuilder now to
    % make sure that the VariableNames normalization warning only shows
    % up once.
    tb = matlab.io.internal.common.builder.TableBuilder();
    tb.Options = opts;
    tb.OriginalVariableNames = tb.OriginalVariableNames; % Trigger VariableNames cross-validation
                                                         % with VariableNamingRule.

    % Set the DimensionNames names properties next to make sure that they
    % are normalized wrt VariableNames.
    % We don't have the same issue as the OriginalVariableNames/VariableNames
    % construction issue here since setting these don't warn.
    tb = setFieldIfSupplied(tb, "OriginalDimensionNames");
    tb = setFieldIfSupplied(tb, "DimensionNames");

    % Populate VariableTypes if supplied.
    tb = setFieldIfSupplied(tb, "VariableTypes");

    % If none of the SelectedVariable* properties are supplied, then
    % we select all the variables by default.
    if ~isfield(args, "SelectedVariableNames") ...
        && ~isfield(args, "OriginalSelectedVariableNames") ...
        && ~isfield(args, "SelectedVariableIndices")
        tb.SelectedVariableIndices = 1:numel(tb.VariableNames);
    end

    % Now that VariableNames is correctly set, handle
    % SelectedVariableNames next. These call validating setters
    % which will throw if an invalid name is provided.
    tb = setFieldIfSupplied(tb, "OriginalSelectedVariableNames");
    tb = setFieldIfSupplied(tb, "SelectedVariableNames");

    % Handle SelectedVariableIndices last so that it can act as an
    % override if SelectedVariableNames are not correct.
    tb = setFieldIfSupplied(tb, "SelectedVariableIndices");

    % Since SelectedVariableIndices and VariableTypes are already
    % populated, just set SelectedVariableTypes normally if its supplied.
    tb = setFieldIfSupplied(tb, "SelectedVariableTypes");

    % RowFilter is just directly populated from the supplied value.
    tb = setFieldIfSupplied(tb, "OriginalRowFilter");
    tb = setFieldIfSupplied(tb, "RowFilter");
end
