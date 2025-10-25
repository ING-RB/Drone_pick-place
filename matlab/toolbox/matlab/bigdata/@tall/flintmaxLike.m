function y = flintmaxLike(prototype)
%FLINTMAXLIKE flintmax "like" a tall array
%   T = flintmaxLike(P) is a tall scalar with the value of flintmax for the
%   underlyingType of P and matching all other attributes.
%
%   P must have floating-point underlying type.
%
%   See also: flintmax, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@flintmax, {'float'}, prototype);
