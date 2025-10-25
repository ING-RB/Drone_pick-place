function C = atan2d(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@atan2d, ...
        @matlab.internal.tabular.math.logicalUnitsHelper);
