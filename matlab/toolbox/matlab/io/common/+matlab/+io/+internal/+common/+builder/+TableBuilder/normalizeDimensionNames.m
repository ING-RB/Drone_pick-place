function normalizedDimensionNames = normalizeDimensionNames(opts)
%normalizeDimensionNames   Use matlab.internal.tabular.makeValidVariableNames() to
%   make the OriginalDimensionNames valid while also making them unique wrt
%   VariableNames.
%
%   Input must be a matlab.io.internal.common.builder.TableBuilderOptions object.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
    end

    normalizedDimensionNames = opts.OriginalDimensionNames;

    % Fill-in the default DimensionNames if either of the input DimensionNames
    % are empty.
    % We have to do this here since makeValidVariableNames() will fill them in
    % with "Var1", "Var2" instead if it gets a strlength=0 input.
    if strlength(normalizedDimensionNames(1)) == 0
        normalizedDimensionNames(1) = opts.DefaultDimensionNames(1);
    end

    if strlength(normalizedDimensionNames(2)) == 0
        normalizedDimensionNames(2) = opts.DefaultDimensionNames(2);
    end

    % Normalize away reserved table identifiers. Use "resolveConflict" mode
    % to avoid any warnings being shown.
    import matlab.internal.tabular.makeValidVariableNames
    normalizedDimensionNames = makeValidVariableNames(normalizedDimensionNames, "resolveConflict");

    % Now make unique wrt opts.VariableNames.
    varNames = opts.VariableNames;
    if any(normalizedDimensionNames' == varNames, "all")
        normalizedDimensionNames = matlab.lang.makeUniqueStrings(normalizedDimensionNames, varNames, namelengthmax);
    end
end
