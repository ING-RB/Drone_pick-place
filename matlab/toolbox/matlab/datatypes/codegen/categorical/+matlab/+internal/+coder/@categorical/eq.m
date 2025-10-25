function t = eq(a,b)   %#codegen
%EQ Equality for categorical arrays.

%   Copyright 2018-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[acodes,bcodes] = reconcileCategories(a,b,false);

% Undefined elements cannot be equal to anything.
if isscalar(acodes) % faster scalar case
    if acodes > 0  %categorical.undefCode
        t = (acodes == bcodes);
    else
        t = false(size(bcodes));
    end
elseif isscalar(bcodes) % faster scalar case
    if bcodes > 0  %categorical.undefCode
        t = (acodes == bcodes);
    else
        t = false(size(acodes));
    end
else
    t = (acodes == bcodes) & (acodes ~= 0);
end

