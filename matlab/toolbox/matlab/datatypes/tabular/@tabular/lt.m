function C = lt(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@lt, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
