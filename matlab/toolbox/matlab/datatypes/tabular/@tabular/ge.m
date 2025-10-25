function C = ge(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@ge, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
