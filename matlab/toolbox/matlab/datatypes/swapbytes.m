function out = swapbytes(in)
%SWAPBYTES Swap byte ordering, changing endianness.
%    Y = SWAPBYTES(X) reverses the byte ordering of each element in X,
%    converting little-endian values to big-endian (and vice versa).
%
%    Example:
%
%       X = uint16([0 1 128 65535]);  % [0x0000 0x0001 0x0080 0xffff]
%       Y = swapbytes(X);             % [0x0000 0x0100 0x8000 0xffff]
%
%    Y will have the following uint16 values:
%
%       [0    256  32768  65535]
%
%    Examining the output in hex notation shows the byte swapping:
%
%       format hex
%       X, Y
%       format
%    
%    See also TYPECAST.

%   Copyright 1984-2024 The MathWorks, Inc.

% No need to swap arrays with byte-sized elements.
if isa(in, 'uint8') || isa(in, 'int8') || isempty(in)
    out = in;
    return
end

% Typecast the input into bytes, reshaping it into bytes-by-numel_in.
cls = class(in);
out = reshape(typecast(in(:), 'like', uint8(1)), getBytesPerElement(cls), []);

% Flip the array, reshape to a vector, and convert back to the input type.
out = flip(out, 1);
out = typecast(out(:), 'like', in);

% Reshape the array to match the input type.
out = reshape(out, size(in));

function numbytes = getBytesPerElement(cls)

switch cls
    case {'uint16', 'int16'}
        numbytes = 2;
    case {'uint32', 'int32', 'single'}
        numbytes = 4;
    case {'uint64', 'int64', 'double'}
        numbytes = 8;
    otherwise
        error(message('MATLAB:swapbytes:InvalidType'));
end
