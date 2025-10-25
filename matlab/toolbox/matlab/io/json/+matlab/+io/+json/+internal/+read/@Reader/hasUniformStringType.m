function bool = hasUniformStringType(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    bool = isscalar(unique(r.getStringTypes(opts)));
end
