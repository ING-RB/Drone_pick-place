function p = isTextRow(x)
%MATLAB Code Generation Private Function
%
%   Return a constant TRUE if x is a scalar string, a char row vector, or
%   the empty char array '', otherwise return false. This function is more
%   restrictive than coder.internal.isCharOrScalarString because in order
%   for it to return TRUE, char inputs must be row-vectors and string
%   inputs must be fixed-size scalars.
%
%   This function evaporates, leaving behind a constant TRUE or FALSE.

%   Copyright 2017-2020 The MathWorks, Inc.
%#codegen

coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.inline('always');
if ischar(x)
    ISROW = coder.internal.isConstTrue(isrow(x));
    ISEMPTY = coder.internal.isConst(size(x)) && isequal(size(x),[0,0]);
    p = coder.const(ISROW || ISEMPTY);
elseif isstring(x)
    p = coder.internal.isConstTrue(isscalar(x));
else
    p = false;
end
