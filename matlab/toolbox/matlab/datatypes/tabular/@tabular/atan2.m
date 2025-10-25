function C = atan2(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@atan2, ...
        @matlab.internal.tabular.math.logicalUnitsHelper);
