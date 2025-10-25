function unpacked_array = matlab2arrow(array)
%MATLAB.IO.ARROW.MATLAB2ARROW
%   Deconstructs a native MATLAB array into a primitive array or a struct array
%   which can be used by the MEX layer.
%   Also does UTF-16 to UTF-8 conversion for strings types, and bit-packing for
%   logical types.

%   Copyright 2018-2021 The MathWorks, Inc.

    try
        if istabular(array)
            % The internal matlab2arrow function converts tabular data to arrow
            % StructArrays, so we have to manually call buildTableStruct here
            % if the original input was a table.
            unpacked_array = matlab.io.arrow.internal.matlab2arrow.buildTableStruct(array);
        else
            unpacked_array = matlab.io.arrow.internal.matlab2arrow(array);
        end
    catch ME
        if isa(ME, "matlab.io.internal.arrow.error.ArrowException")

            varName = getVariableName(array);
            indexExpression = getIndexingExpression(ME, varName);
            ME = MException(ME.identifier, message(ME.identifier, indexExpression{:}, ME.MessageHoleValues{:}));
        end
        throw(ME);
    end

end

function varName = getVariableName(inputArray)
    if istable(inputArray)
        varName = "T";
    elseif istimetable(inputArray)
        varName = "TT";
    else
        varName = "A";
    end
end
