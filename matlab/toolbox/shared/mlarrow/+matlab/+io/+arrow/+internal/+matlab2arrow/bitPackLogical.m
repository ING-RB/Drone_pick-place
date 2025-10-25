function bitPackStruct = bitPackLogical(array)
%BITPACKLOGICAL
%   Bit-packs logical arrays to be passed to the C++ layer.
%
% ARRAY is a logical Nx1 array.
%
% BITPACKSTRUCT is a scalar struct.
%
% BITPACKSTRUCT contains the following fields:
%
% Field Name    Class      Description
% ----------    ------     -------------------------
% Values        uint8      Bit-packed representation
%                          of the logical array.
% Length        double     Length of the original array.
% ArrowType     char       Always set to 'buffer'.

%   Copyright 2021 The MathWorks, Inc.


    if isempty(array)
        bitPackStruct = struct("Values", uint8.empty(0, 1), "ArrowType", 'buffer',...
            "Length", 0);
        return;
    end

    % Pad with extra false values so that array is always a multiple of 8.
    array_length = numel(array);
    bit_packed_length = array_length + (8 - mod(array_length, 8));
    array(end+1:bit_packed_length, :) = false; % pad zeros in the final byte.

    % Create the powers of 2
    powers = 0x2u8 .^ (0x0u8:0x7u8)';

    % array should be reshapeable to an 8-by-n matrix.
    array = reshape(array, 8, []);

    % Convert to uint8 so that mtimes doesn't complain.
    array = uint8(array);

    % Use times to get the fractional part for each bit. Sum the values to
    % form a full byte.
    array = powers .* array;
    array = sum(array, 1, 'native')';

    bitPackStruct = struct("Values", array, "ArrowType", 'buffer',...
        "Length", array_length);
end

