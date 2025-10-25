function [sorted,i] = mink(unsorted,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

if ~isnumeric(k)
    error(message('MATLAB:topk:InvalidK'));
end

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:mink:InvalidAbsRealType'));
    end
end

if ~isempty(varargin) && ~isnumeric(varargin{1})
    error(message('MATLAB:topk:notPosInt'));
end

sorted = unsorted;
if nargout < 2
    sorted.millis = mink(unsorted.millis,k,varargin{:});
else
    [sorted.millis,i] = mink(unsorted.millis,k,varargin{:});
end
