function C = gt(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@gt, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
