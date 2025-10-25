function bufferArray = buildBufferArray(bufferStruct)
%BUILDLOGICAL
%   Builds creates logical arrays from bit-packed uint8 arrays.
%
%
% ARROW_BUFFER_STRUCT is an 1x1 struct.
%
% ARROW_BUFFER_STRUCT contains the follow fields:
% 
% Field Name    Class      Description
% ----------    ------     --------------------------------
% ArrowType     char       Always set to 'buffer'
% Values        uint8      bitpacked data
% Length        double     Length of the data once unpacked

%   Copyright 2021 The MathWorks, Inc.

    arguments
        bufferStruct (:, 1) struct {mustBeEmptyOrScalar, mustBeArrowBufferStruct}
    end

    import matlab.io.arrow.internal.validateStructFields;


    % Return if an empty chunked_array is passed in.
    if isempty(bufferStruct)
        bufferArray = logical([]);
        return;
    end

    % Compute powers of two for later division.
    powers = uint8(2 .^ (0:7));

    % pre-allocate working and result arrays
    bit_packed_length = length(bufferStruct.Values);

    % Extract the individual bits from the bit-packed array by doing a
    % vectorized bit-shift using a division operation.
    % We want to do a floor divide operation here to unpack the bit-packed
    % array. However, we don't want to allocate an additional matrix to
    % store the expanded powers of two (or expand to a double array).
    % Therefore, use a binary singleton expansion to save memory while
    % also vectorizing the division operation.
    expanded_bitmap = bsxfun(@idivide, bufferStruct.Values, powers);

    % Normalize the bitmap to integral values.
    normalized_bitmap = mod(expanded_bitmap, 2);

    % Convert to logical bit mask and reshape to a 1-D array.
    unpacked_matrix = logical(normalized_bitmap);
    result = reshape(unpacked_matrix', bit_packed_length * 8, 1);

    % If an empty validity bitmap is passed, then all the elements
    % in the array are valid.
    if isempty(bufferStruct.Values) && (bufferStruct.Length > 0)
        bufferArray = true(bufferStruct.Length, 1);
    else
        % Truncate array down to actual length
        bufferArray = result(1:bufferStruct.Length);
    end
end

function mustBeEmptyOrScalar(bufferStruct)
    if size(bufferStruct, 1) > 1
        error(message("MATLAB:io:arrow:arrow2matlab:WrongStructSize"));
    end
end

function mustBeArrowBufferStruct(bufferStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Values", "Length"];
    validateStructFields(bufferStruct, requiredFields);
    
    if numel(bufferStruct) > 0 && bufferStruct.ArrowType ~= "buffer"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "buffer", bufferStruct.ArrowType));
    end

end