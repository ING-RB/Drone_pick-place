function x = odesolve(Factors, piv, b)
% Solving with the compact factor form from odefactorize

%   Copyright 1984-2024 The MathWorks, Inc.

if isa(Factors, 'decomposition')
    x = Factors\b;
else
    x = matlab.internal.decomposition.builtin.luSolve(Factors,piv,cast(b,"like",Factors));
end
