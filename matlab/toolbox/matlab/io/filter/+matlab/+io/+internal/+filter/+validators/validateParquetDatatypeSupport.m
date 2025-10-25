function rf = validateParquetDatatypeSupport(rf, allowMissing)
%validateParquetDatatypeSupport   validates the *legacy* requirements of a
%   supported RowFilter operand.
%   In R2023a and newer, RowFilter constraints can be expressed with any
%   operand.
%   But in R2022b and older, RowFilter only allowed a subset of supported
%   Parquet types as operands.
%   Use this function to recover the old Parquet-centric validation
%   behavior.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        rf (1, 1) matlab.io.internal.AbstractRowFilter
        allowMissing (1, 1) logical = false
    end

    fcn = @(x) datatypeValidator(x, allowMissing);

    rf = traverse(rf, fcn);
end

function rf = datatypeValidator(rf, allowMissing)
    if ~isa(rf, "matlab.io.internal.filter.SingleVariableRowFilter")
        % Do nothing by default.
        return;
    end

    % Perform operand validation for SingleVariableRowFilters.
    import matlab.io.internal.filter.validators.validateSupportedOperand
    props = getProperties(rf);
    props.Operand = validateSupportedOperand(props.Operand, allowMissing);
    rf = setProperties(rf, props);
end