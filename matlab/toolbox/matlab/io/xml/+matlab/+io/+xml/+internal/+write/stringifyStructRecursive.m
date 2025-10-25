function value = stringifyStructRecursive(value, attributeSuffix, debugString)
% Validate that all the fields in the struct have valid datatypes and size.
% Uses recursion rather than subsref-based iteration to traverse through
% the input struct, which provides some performance benefits.

% Copyright 2020 The MathWorks, Inc.

    import matlab.io.xml.internal.write.*;

    if nargin < 3
        % If we detect an issue somewhere in the middle of validation, it
        % would be nice to print an indexing expression that can help the
        % user zoom in to the exact part of their struct that is causing
        % the error.
        % This 'debugString' is augmented as we iterate through the input
        % struct, so that we could print something like "S.A.B(3).C" as the
        % source of an error.
        debugString = "S";
    end

    if isstruct(value)
        value = stringifyStructOneLevel(value, attributeSuffix, debugString);
    elseif isSupportedDatatype(value)
        value = stringifySupportedDatatype(value, debugString);
    else
        % The input datatype is not a supported one, and is not a struct.
        % Error since it must be an invalid datatype.
        throwUnsupportedDatatypeError(class(value), debugString);
    end
end

function value = stringifyStructOneLevel(value, attributeSuffix, debugString)

    import matlab.io.xml.internal.write.*;

    if isEmptyStruct(value)
        % Skip all of this if the top-level struct doesn't have fieldnames
        % or is empty.
        return;
    end

    % Struct dimension and fieldname validation.
    fnames = string(fieldnames(value));
    validateStructArrayDimensions(value, debugString);
    validateFieldnameDoesNotMatchAttributeSuffix(fnames, attributeSuffix);
    
    for i = 1:length(fnames)
        fieldToValidate = fnames(i);
        isAttribute = false;
        if endsWith(fnames(i), attributeSuffix) 
            fieldToValidate = extractBefore(fieldToValidate, ...
                strlength(fnames(i)) - strlength(attributeSuffix) + 1);
            isAttribute = true;
        end
        validateXMLElement(fieldToValidate, fnames(i), isAttribute);
    end

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
                stringifyStructRecursive(value(vector_index).(fieldname), ...
                    attributeSuffix, fieldDebugString);
        end
    end
end

function validateStructArrayDimensions(s, debugString)
    import matlab.io.xml.internal.write.*;
    if ~hasAtMostOneDimension(s)
        throwUnsupportedDimensionsError(debugString);
    end
end

function validateFieldnameDoesNotMatchAttributeSuffix(fnames, attributeSuffix)
    % Error if the AttributeSuffix is an exact match of any fieldname.
    if any(fnames == attributeSuffix)
        import matlab.io.xml.internal.write.*;
        throwExactAttributeSuffixMatchError(attributeSuffix);
    end
end

function tf = isEmptyStruct(s)
    tf = false;
    if isempty(s) || numel(fieldnames(s)) == 0
        tf = true;
    end
end
