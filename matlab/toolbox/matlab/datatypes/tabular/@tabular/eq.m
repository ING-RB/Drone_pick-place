function C = eq(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@eq, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
