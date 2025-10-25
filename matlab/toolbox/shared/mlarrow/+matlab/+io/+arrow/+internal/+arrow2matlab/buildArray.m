function result = buildArray(arrayStruct, opts)
%BUILDARRAY Builds a MATLAB array specified by the input ARROWSTRUCT.

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        arrayStruct (1,1) struct {mustBeArrowArrayStruct}
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions
    end

    import matlab.io.arrow.internal.Arrow2MatlabOptions

    import matlab.io.arrow.internal.arrow2matlab.*

    % The Valid field is either a 0x1 or 1x1 struct representing an
    % arrow::Buffer. Because it can be empty, avoid invoking
    % matlab.io.arrow.internal.arrow2matlab because that function requires
    % a scalar struct as input.
    nullIndices = ~(buildBufferArray(arrayStruct.Valid));

    switch arrayStruct.Type
        case "logical"
            result = buildLogical(arrayStruct.Data, nullIndices, LogicalTypeConversionOptions=opts.ArrowTypeConversionOptions.LogicalTypeConversionOptions);
        case "string"
            result = arrayStruct.Data;
            result(nullIndices) = missing;
        case "categorical"
            result = buildCategorical(arrayStruct.Data, nullIndices);
        case "datetime"
            result = buildDatetime(arrayStruct.Data, nullIndices, opts);
        case "duration"
            result = buildDuration(arrayStruct.Data, nullIndices);
        case {'uint8', 'uint16', 'uint32', 'uint64', ...
                'int8', 'int16', 'int32', 'int64', ...
                'single', 'double'}
            result = buildNumeric(arrayStruct.Data, nullIndices, IntegerTypeConversionOptions=opts.ArrowTypeConversionOptions.IntegerTypeConversionOptions);
        case {'binary_array', 'fixed_binary_array'}
            result = buildBinary(arrayStruct.Data, nullIndices);
        case "null"
            result = NaN(arrayStruct.Data, 1, "double");
        otherwise
            id = "MATLAB:io:arrow:arrow2matlab:UnknownDataType";
            error(message(id, arrayStruct.Type));
    end
end

function mustBeArrowArrayStruct(arrayStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Type", "Data", "Valid"];
    validateStructFields(arrayStruct, requiredFields);
    if arrayStruct.ArrowType ~= "array"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "array", arrayStruct.ArrowType));
    end
end
