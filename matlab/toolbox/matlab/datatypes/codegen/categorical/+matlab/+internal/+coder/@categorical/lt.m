function t = lt(a,b)   %#codegen
%LT Less than for ordinal categorical arrays.

%   Copyright 2018-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[acodes,bcodes] = reconcileCategories(a,b,true);

% Undefined elements cannot be less than anything.
if isscalar(acodes) % faster scalar case
    if acodes > 0 % categorical.undefCode
        t = (acodes < bcodes);
    else
        t = false(size(bcodes));
    end
else
    t = (acodes < bcodes) & (acodes ~= 0);
end
