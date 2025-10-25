function y = epsLike(prototype)
%EPSLIKE eps "like" a tall array
%   T = epsLike(P) is a tall scalar with the value of eps for the
%   underlyingType of P and matching all other attributes.
%
%   P must have floating-point underlying type.
%
%   See also: eps, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@eps, {'float'}, prototype);
