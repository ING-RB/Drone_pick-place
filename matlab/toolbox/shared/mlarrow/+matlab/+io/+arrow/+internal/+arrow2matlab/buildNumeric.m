function numericArray = buildNumeric(inputArray, nullIndices, opts)
%BUILDRESULT Summary of this function goes here
%   Detailed explanation goes here
    arguments
        inputArray {mustBeNumeric}
        nullIndices logical
        opts.IntegerTypeConversionOptions (1, 1) matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.IntegerTypeConversionOptions()
    end

    numericArray = inputArray;
    
    nullFillValue = NaN;

    if any(nullIndices)
        % MATLAB does not support missing values for integer types.
        % As a partial workaround, clients can optionally choose to cast
        % logical arrays to double to support NaN for missing values (or some
        % other custom sentinel value).
        if isinteger(numericArray)
            if opts.IntegerTypeConversionOptions.CastToDouble
                numericArray = double(numericArray);
            else
                nullFillValue = opts.IntegerTypeConversionOptions.NullFillValue;
            end
        end

        numericArray(nullIndices) = nullFillValue;
    end
end

