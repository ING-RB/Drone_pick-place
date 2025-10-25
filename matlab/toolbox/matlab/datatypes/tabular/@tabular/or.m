function C = or(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@or, ...
        @matlab.internal.tabular.math.logicalUnitsHelper);
