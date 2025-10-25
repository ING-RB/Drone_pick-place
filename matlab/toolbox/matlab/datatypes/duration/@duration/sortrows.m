function [sorted,i] = sortrows(unsorted,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sortrows:InvalidAbsRealType',class(unsorted)));
    end
end
sorted = unsorted;
if nargout < 2
    sorted.millis = sortrows(unsorted.millis,varargin{:});
else
    [sorted.millis,i] = sortrows(unsorted.millis,varargin{:});
end
