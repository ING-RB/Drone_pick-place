function [sorted,i] = topkrows(unsorted,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:topkrows:InvalidAbsRealType'));
    end
end
sorted = unsorted;
if nargout < 2
    sorted.millis = topkrows(unsorted.millis,k,varargin{:});
else
    [sorted.millis,i] = topkrows(unsorted.millis,k,varargin{:});
end
