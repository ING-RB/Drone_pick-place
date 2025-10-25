function name = idxToStructName(idx)
%#codegen

%   Copyright 2020 The MathWorks, Inc.

assert(idx >= 0);
coder.const(idx);
name = ['f', num2str(idx)];

end
