function t = gt(a,b)   %#codegen
%GT Greater than for ordinal categorical arrays.

%   Copyright 2018-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[acodes,bcodes] = reconcileCategories(a,b,true);

% Undefined elements cannot be greater than anything.
if isscalar(bcodes) % faster scalar case
    if bcodes > 0 % categorical.undefCode
        t = (acodes > bcodes);
    else
        t = false(size(acodes));
    end
else
    t = (acodes > bcodes) & (bcodes ~= 0);
end
