function p = lastBitOfSizeInt(n)
%MATLAB Code Generation Private Function
%
%   Determines the last bit of a non-negative integer n.
%   Output is indeterminate if n is non-integer or negative.

%   Copyright 2019 The MathWorks, Inc.
%#codegen

if coder.target('MATLAB')
    p = bitand(n,1) == 1;
    return
end

% Always use an unsigned integer class.
coder.inline('always');
coder.internal.prefer_const(n);
if isinteger(n)
    ucls = coder.internal.unsignedClass(class(n));
else
    ucls = coder.internal.unsignedClass(coder.internal.indexIntClass);
end
p = bitand(eml_cast(n,ucls,'spill'),ones(ucls)) == 1;
