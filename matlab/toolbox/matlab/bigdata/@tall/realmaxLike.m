function y = realmaxLike(prototype)
%REALMAXLIKE realmax "like" a tall array
%   T = realmaxLike(P) is a tall scalar with the value of realmax for the
%   underlyingType of P and matching all other attributes.
%
%   P must have floating-point underlying type.
%
%   See also: realmax, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@realmax, {'float'}, prototype);
