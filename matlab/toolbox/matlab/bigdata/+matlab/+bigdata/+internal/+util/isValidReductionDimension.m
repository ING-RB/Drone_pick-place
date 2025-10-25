function tf = isValidReductionDimension(dims)
% Check that the reduction dimension is either "all" or is a vector of
% positive integers.

% Copyright 2018-2023 The MathWorks, Inc.

if matlab.bigdata.internal.util.isAllFlag(dims)
    tf = true;
    return;
end

% Numeric dimension, so check that it's a vector of positive integers. A
% 0x1 or 1x0 vector is also allowed.
if isempty(dims)
    tf = isnumeric(dims) && isvector(dims);
else
    tf = isnumeric(dims) && isvector(dims) && isreal(dims) ...
        && all(isfinite(dims)) && all(dims>=1) ...
        && all(dims==round(dims));
end
end
