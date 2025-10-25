function [sorted,i] = sortrows(unsorted,varargin) %#codegen
%SORTROWS Sort rows of a matrix of durations.

%   Copyright 2020 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),'MATLAB:sortrows:InvalidAbsRealType',class(unsorted));
end
sorted = unsorted;
if nargout < 2
    sorted.millis = sortrows(unsorted.millis,varargin{:});
else
    [sorted.millis,i] = sortrows(unsorted.millis,varargin{:});
end
