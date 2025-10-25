function tf = isUniqueNumeric(x) %#codegen
% ISUNIQUENUMERIC check if a numeric array contains only unique elements
%    TF = ISUNIQUENUMERIC(X) returns true if a numeric array X contains 
%    only unique elements and false otherwise. ISUNIQUENUMERIC does not
%    check for correct type, error conditions, nor return index of unique
%    elements.
   
%   Copyright 2020 The MathWorks, Inc.
coder.extrinsic('matlab.internal.datatypes.isUniqueNumeric');
coder.internal.prefer_const(x);
if coder.internal.isConst(x)
    tf = coder.const(matlab.internal.datatypes.isUniqueNumeric(x));
else
    tf = all(diff(sort(x(:))));
end
end
