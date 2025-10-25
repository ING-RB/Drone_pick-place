function doNotOptimizeROS2(input)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2022 The MathWorks, Inc.
%#codegen
coder.inline('always');
coder.ceval('//',input);
end
