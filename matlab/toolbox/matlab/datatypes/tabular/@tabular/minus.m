function C = minus(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@minus, ...
        @matlab.internal.tabular.math.plusUnitsHelper);
