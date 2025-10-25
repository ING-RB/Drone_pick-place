function C = power(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@power, ...
        @matlab.internal.tabular.math.powerUnitsHelper);
