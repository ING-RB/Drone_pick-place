function t = ge(a,b)
%

%   Copyright 2006-2024 The MathWorks, Inc.

[acodes,bcodes] = reconcileCategories(a,b,true);

% Undefined elements cannot be greater than or equal to anything
if isscalar(bcodes) % faster scalar case
    if bcodes > 0 % categorical.undefCode
        t = (acodes >= bcodes);
    else
        t = false(size(acodes));
    end
else
    t = (acodes >= bcodes) & (bcodes ~= 0);
end
