function C = rem(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@rem, ...
        @matlab.internal.tabular.math.plusUnitsHelper);
