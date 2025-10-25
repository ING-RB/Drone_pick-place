function yi = noneExtrapolationKernel(~, ~, yi, nFuncVal, ~)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen
coder.inline('always')
coder.internal.prefer_const(nFuncVal)
for j = 0:nFuncVal-1
    yi(j+1) = nan;
end
