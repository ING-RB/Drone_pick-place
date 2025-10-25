function C = mod(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@mod, ...
        @matlab.internal.tabular.math.plusUnitsHelper);
