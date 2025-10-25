function C = times(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@times, ...
        @matlab.internal.tabular.math.timesUnitsHelper);
