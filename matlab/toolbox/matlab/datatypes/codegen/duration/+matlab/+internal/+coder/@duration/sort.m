function [sorted,i] = sort(unsorted,varargin) %#codegen
%SORT Sort durations in ascending or descending order.

%   Copyright 2020 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),'MATLAB:sort:InvalidAbsRealType',class(unsorted));
end
sorted = unsorted;
if nargout < 2
    sorted.millis = sort(unsorted.millis,varargin{:});
else
    [sorted.millis,i] = sort(unsorted.millis,varargin{:});
end
