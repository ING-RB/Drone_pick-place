function C = le(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@le, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
