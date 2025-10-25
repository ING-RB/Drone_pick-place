function A = pow2(A,B)
%

% Copyright 2022-2024 The MathWorks, Inc.

if nargin == 1
    A = tabular.unaryFunHelper(A,@pow2,false,{});
elseif nargin == 2
    A = tabular.binaryFunHelper(A,B,@pow2, ...
        @matlab.internal.tabular.math.powerUnitsHelper);
end
