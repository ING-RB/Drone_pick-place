function [sorted,ind] = sortrows(this,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sortrows:InvalidAbsRealType',class(this)));
    end
end
% Lexicographic sort of complex data
if nargout < 2
    newdata = sortrows(this.data,varargin{:},'ComparisonMethod','real');
else
    [newdata,ind] = sortrows(this.data,varargin{:},'ComparisonMethod','real');
end
sorted = this;
sorted.data = newdata;
