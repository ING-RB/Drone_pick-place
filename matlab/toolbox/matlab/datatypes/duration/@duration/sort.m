function [sorted,i] = sort(unsorted,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sort:InvalidAbsRealType',class(unsorted)));
    end
end
sorted = unsorted;
if nargout < 2
    sorted.millis = sort(unsorted.millis,varargin{:});
else
    [sorted.millis,i] = sort(unsorted.millis,varargin{:});
end
