function value = validateJSONStruct(value, debugString)
% Validate that all the fields in the struct have valid datatypes and size.
% Uses recursion rather than subsref-based iteration to traverse through
% the input struct, which provides some performance benefits.

% Copyright 2023-2024 The MathWorks, Inc.

    if nargin < 2
        % If we detect an issue somewhere in the middle of validation, it
        % would be nice to print an indexing expression that can help the
        % user zoom in to the exact part of their struct that is causing
        % the error.
        % This 'debugString' is augmented as we iterate through the input
        % struct, so that we could print something like "S.A.B(3).C" as the
        % source of an error.
        debugString = "S";
    end

    import matlab.io.xml.internal.write.throwUnsupportedDatatypeError

    if isstruct(value)
        value = validateStructOneLevel(value, debugString);
    elseif iscell(value)
        value = validateCellOneLevel(value, debugString);
    elseif isSupportedDatatypeNoConversion(value)
        value = validateArrayDimensions(value, debugString);
    elseif isSupportedDatatypeNeedsConversion(value)
        value = validateArrayDimensions(value, debugString);
        value = string(value);
    else
        % The input datatype is not a supported one, and is not a struct.
        % Error since it must be an invalid datatype.
        throwUnsupportedDatatypeError(class(value), debugString);
    end
end

function value = validateStructOneLevel(value, debugString)

    import matlab.io.json.internal.write.validateJSONStruct;

    validateArrayDimensions(value, debugString);
    fnames = string(fieldnames(value));

    % Iterate over the struct dimensions.
    for vector_index = 1:numel(value)
        if numel(value) == 1
            % Avoid setting the "S(1)" index here to make the indexing
            % expression look cleaner when an error is thrown.
            vectorDebugString = debugString;
        else
            vectorDebugString = debugString + "(" + vector_index + ")";
        end

        % Iterate over the struct fields.
        for field_index = 1:numel(fnames)
            fieldname = fnames(field_index);
            fieldDebugString = vectorDebugString + "." + fieldname;

            % Recurse.
            value(vector_index).(fieldname) = ...
                validateJSONStruct(value(vector_index).(fieldname), ...
                                   fieldDebugString);
        end
    end
end

function value = validateCellOneLevel(value, debugString)
    import matlab.io.json.internal.write.validateJSONStruct;

    validateArrayDimensions(value, debugString);

    for index = 1:numel(value)
        elementDebugString = debugString + "{" + index + "}";

        % Recurse.
        value{index} = validateJSONStruct(value{index}, elementDebugString);
    end
end

function s = validateArrayDimensions(s, debugString)
    import matlab.io.xml.internal.write.*;
    if ~isempty(s) && ~hasAtMostOneDimension(s)
        throwUnsupportedDimensionsError(debugString);
    end
end

function tf = isSupportedDatatypeNoConversion(data)
    tf = isstring(data) ...
         || isnumeric(data) ...
         || islogical(data);
end

function tf = isSupportedDatatypeNeedsConversion(data)
    tf = class(data) == "missing" ...
         || ischar(data) ...
         || isdatetime(data) ...
         || isduration(data) ...
         || iscalendarduration(data) ...
         || iscategorical(data);
end
