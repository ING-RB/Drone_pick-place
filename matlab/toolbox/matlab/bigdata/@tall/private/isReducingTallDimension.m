function tf = isReducingTallDimension(dims)
% Check wether the reduction dimension includes the first dimension.

% Copyright 2018 The MathWorks, Inc.
tf = matlab.bigdata.internal.util.isAllFlag(dims) ...
    || (isnumeric(dims) && isrow(dims) && any(dims == 1));
end
