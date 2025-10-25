function C = plus(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@plus, ...
        @matlab.internal.tabular.math.plusUnitsHelper);
