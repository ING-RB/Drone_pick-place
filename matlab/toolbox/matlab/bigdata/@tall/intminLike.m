function y = intminLike(prototype)
%INTMINLIKE intmin "like" a tall array
%   T = intminLike(P) is a tall scalar with the value of intmin for the
%   underlyingType of P and matching all other attributes.
%
%   P must have integer underlying type.
%
%   See also: intmin, tall.

%   Copyright 2021 The MathWorks, Inc.

y = buildScalarLike(@intmin, {'integer'}, prototype);
