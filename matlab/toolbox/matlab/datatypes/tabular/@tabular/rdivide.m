function C = rdivide(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@rdivide, ...
        @matlab.internal.tabular.math.divideUnitsHelper);
