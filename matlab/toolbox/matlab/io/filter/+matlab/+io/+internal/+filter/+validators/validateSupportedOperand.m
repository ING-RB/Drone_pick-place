function value = validateSupportedOperand(value, allowMissing)
%validateSupportedOperand   validates the *legacy* requirements of a
%   supported RowFilter operand.
%   In R2023a and newer, RowFilter constraints can be expressed with any
%   operand.
%   But in R2022b and older, RowFilter only allowed a subset of supported
%   Parquet types as operands.
%   Use this function to recover the old Parquet-centric validation
%   behavior.

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        value
        allowMissing (1, 1) logical = false
    end

    % Empty (0-by-0) char vectors are allowed.
    % Must be a 2D empty, instead of an ND empty.
    isEmptyChar = ischar(value) && ismatrix(value) && ...
                    size(value, 1) == 0 && size(value, 2) == 0;

    % Nonempty char row vectors are allowed.
    isNonemptyChar = ischar(value) && isrow(value);

    if isEmptyChar || isNonemptyChar
        % Convert the char to string.
        value = string(value);
        return;
    end

    isSupportedMissingValue = allowMissing && ismissing(value);

    if isscalar(value) && ...
            ((isnumeric(value) && isreal(value)) ...
             || isstring(value) ...
             || isdatetime(value) ...
             || isduration(value) ...
             || iscategorical(value) ...
             || islogical(value)) ...
             || isSupportedMissingValue
        if ~allowMissing && ismissing(value)
            % Missing values aren't supported for Parquet filter operands.
            error(message("MATLAB:io:filter:filter:MissingNotSupported"));
        end
        return;
    end

    % Unsupported datatype.
    error(message("MATLAB:io:filter:filter:InvalidFilterOperand"));
end
