function [Factors, piv] = odefactorize(A)
% Factorize A into a compact factors form

%   Copyright 2022 The MathWorks, Inc.

if issparse(A) && size(A,1) > 100
    Factors = decomposition(A,'CheckCondition',false, ...
        'AllowIterativeRefinement', false);
    piv = -1;  % not use
else
    [Factors,piv] = matlab.internal.decomposition.builtin.luFactor(full(A));
end
