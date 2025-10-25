function C = xor(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@xor, ...
        @matlab.internal.tabular.math.logicalUnitsHelper);
