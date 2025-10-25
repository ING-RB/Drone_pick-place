function C = and(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@and, ...
        @matlab.internal.tabular.math.logicalUnitsHelper);
