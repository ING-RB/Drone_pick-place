function t = eq(a,b)
%

%   Copyright 2006-2024 The MathWorks, Inc.

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

