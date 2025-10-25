function y = realminLike(prototype)
%REALMINLIKE realmin "like" a tall array
%   T = realminLike(P) is a tall scalar with the value of realmin for the
%   underlyingType of P and matching all other attributes.
%
%   P must have floating-point underlying type.
%
%   See also: realmin, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@realmin, {'float'}, prototype);
