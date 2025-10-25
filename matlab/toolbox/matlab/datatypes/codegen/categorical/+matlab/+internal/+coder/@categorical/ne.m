function t = ne(a,b)   %#codegen
%NE Not equal for categorical arrays.

%   Copyright 2018-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[acodes,bcodes] = reconcileCategories(a,b,false);

% Undefined elements are not equal to everything.
if isscalar(acodes) % faster scalar case
    if acodes > 0 % categorical.undefCode
        t = (acodes ~= bcodes);
    else
        t = true(size(bcodes));
    end
elseif isscalar(bcodes) % faster scalar case
    if bcodes > 0 % categorical.undefCode
        t = (acodes ~= bcodes);
    else
        t = true(size(acodes));
    end
else
    t = (acodes ~= bcodes) | (acodes == 0) | (bcodes == 0);
end
