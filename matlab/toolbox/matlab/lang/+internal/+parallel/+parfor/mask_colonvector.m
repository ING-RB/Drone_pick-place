function M = mask_colonvector(arg)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2024 The MathWorks, Inc.

% M = mask_colonvector(A,[S,]D,U) returns the indexing element positions of
% the colon vector A:[S:]D less-than or equal-to an upper bound U, otherwise
% returns [].

arguments (Repeating)
    % Use this to coerce already-validated arguments to builtin doubles.
    arg (1,1) double
end

narginchk(3,4);
vec = colon(arg{1:(nargin-1)});
M = vec(vec <= arg{end});
end
