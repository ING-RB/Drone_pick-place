function n = maxSlicesForReduction()
% Return a standard value for the maximum number of slices to use in
% reductions such as HEAD, TAIL, TOPKROWS. These algorithms can switch to
% alternative (but slower) methods if above this threshold.

%   Copyright 2019 The MathWorks, Inc.

n = 1e5;
