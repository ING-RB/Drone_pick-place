function y = intmaxLike(prototype)
%INTMAXLIKE intmax "like" a tall array
%   T = intmaxLike(P) is a tall scalar with the value of intmax for the
%   underlyingType of P and matching all other attributes.
%
%   P must have integer underlying type.
%
%   See also: intmax, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@intmax, {'integer'}, prototype);
