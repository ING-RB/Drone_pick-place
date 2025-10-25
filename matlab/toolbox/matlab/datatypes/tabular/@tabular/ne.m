function C = ne(A,B)
%

%   Copyright 2022-2024 The MathWorks, Inc.

C = tabular.binaryFunHelper(A,B,@ne, ...
        @matlab.internal.tabular.math.relationalUnitsHelper);
