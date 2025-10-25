function C = ldivide(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@ldivide, ...
        @matlab.internal.tabular.math.divideUnitsHelper);
