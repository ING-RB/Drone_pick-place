function A = nthroot(A,B)
%

% Copyright 2022-2024 The MathWorks, Inc.

A = tabular.binaryFunHelper(A,B,@nthroot, ...
    @matlab.internal.tabular.math.powerUnitsHelper);
