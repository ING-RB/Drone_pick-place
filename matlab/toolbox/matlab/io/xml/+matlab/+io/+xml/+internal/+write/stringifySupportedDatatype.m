function value = stringifySupportedDatatype(value, debugString)
%stringifySupportedDatatype   converts a supported input datatype
%   into a string for writestruct.
%
%   NOTE: assumes that 'isSupportedDatatype' has already been validated
%   for the input data. This function does not re-validate the input
%   datatype to improve performance.

%   Copyright 2020 The MathWorks, Inc.

    import matlab.io.xml.internal.write.*;

    % Convert char vectors and cellstrs to strings.
    value = convertCharsToStrings(value);

    isEmpty2DValue = @(value) isempty(value) && ismatrix(value);
    isMissingType = @(value) class(value) == "missing";

    % Early exit cases.
    if isEmpty2DValue(value)
        % 0x0 values are not included in the output xml file.
        value = string.empty;
        return;
    elseif ~hasAtMostOneDimension(value)
        % If not empty, we require all fields to be scalar
        % or vector values.
        throwUnsupportedDimensionsError(debugString);
    elseif isMissingType(value)
        % The "missing" datatype is used to imply that no node should be generated
        % in the XML file for this field.
        value = string.empty;
        return;
    end

    % Stringify!
    value = string(value);
end
