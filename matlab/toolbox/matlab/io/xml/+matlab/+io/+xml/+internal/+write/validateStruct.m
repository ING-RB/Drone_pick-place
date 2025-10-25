function S = validateStruct(S, attributeSuffix)
%

% Copyright 2020 The MathWorks, Inc.

    import matlab.io.xml.internal.write.*;

    % Avoid repeated warnings for invalid node names.
    warningCleanup = suppressMultipleWarnings(); %#ok<NASGU>

    % Validate that the top-level struct is scalar.
    validateattributes(S, "struct", "scalar", "writestruct", "S");

    % Traverse each level of the struct and verify that each field has a
    % supported datatypes. Also convert every field value to a string.
    S = stringifyStructRecursive(S, attributeSuffix);
end
