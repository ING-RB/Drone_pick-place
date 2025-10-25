function t = le(a,b)   %#codegen
%LE Less than or equal to for ordinal categorical arrays.

%   Copyright 2018-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[acodes,bcodes] = reconcileCategories(a,b,true);

% Undefined elements cannot be less than or equal to anything.
if isscalar(acodes) % faster scalar case
    if acodes > 0 % categorical.undefCode
        t = (acodes <= bcodes);
    else
        t = false(size(bcodes));
    end
else
    t = (acodes <= bcodes) & (acodes ~= 0);
end
