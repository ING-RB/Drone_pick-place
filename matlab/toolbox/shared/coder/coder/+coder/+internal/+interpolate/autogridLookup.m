function idx = autogridLookup(x,maxidx)
% Substitute for bsearch when the grid is automatic.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.inline('always')
if x <= 1
    idx = coder.internal.indexInt(1);
elseif x <= maxidx
    idx = coder.internal.indexInt(floor(x));
else
    idx = coder.internal.indexInt(maxidx);
end
