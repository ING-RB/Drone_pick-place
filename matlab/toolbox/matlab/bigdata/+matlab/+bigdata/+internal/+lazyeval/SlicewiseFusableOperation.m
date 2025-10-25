%SlicewiseFusableOperation
% An abstract base class that represents an operation that can be fused
% slicewise.
%
% Abstract methods:
%
% tf = isSlicewiseFusable(obj) checks if this operation can be fused with
% other slicewise fusable objects.
%
% fh = getCheckedFunctionHandle(obj) returns a function handle that
% represents this object to enable optimization with
% SlicewiseFusingOptimizer.

% Copyright 2017-2022 The MathWorks, Inc.
