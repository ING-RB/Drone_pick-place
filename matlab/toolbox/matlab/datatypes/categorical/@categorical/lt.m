function t = lt(a,b)
%

%   Copyright 2006-2024 The MathWorks, Inc.

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
