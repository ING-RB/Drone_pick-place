function x = convertToUnsignedWithSameSpacing(x)
%convertToUnsignedWithSameSpacing Convert unsigned integer data to the
% corresponding signed integer type preserving only spacing between data
% points, not values
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

% Copyright 2023 The Mathworks, Inc.

if isa(x,'int8') || isa(x,'int16') || isa(x,'int32') || isa(x,'int64')
    unsignedClass = ['u' class(x)];
    imax = intmax(unsignedClass);
    leadingOneBit = bitxor(imax,bitshift(imax, -1));
    % unsignedClass integer with bit pattern 100...0

    sizeX = size(x);
    x = reshape(bitxor(typecast(x(:),unsignedClass),leadingOneBit),sizeX); 
    % reinterpret X as unsignedClass, then use leadingOneBit to flip 
    % the leading bit. This converts X to unsignedClass while 
    % preserving the difference between elements
end
end