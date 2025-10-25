function varargout = max(varargin)
%MAX Largest component
%   M = MAX(X)
%   C = MAX(X,Y)
%   [M,I] = MAX(X)
%   [M,I] = MAX(X,[],DIM)
%   [M,I] = MAX(X,[],...,'linear')
%   M = MAX(...,NANFLAG)
%   M = MAX(...,"ComparisonMethod",METHOD)
%
%   Limitations:
%   Index output is not supported for tall tabular inputs.
%
%   See also: MAX, TALL.

%   Copyright 2015-2023 The MathWorks, Inc.

try
    [varargout{1:max(nargout,1)}] = minmaxop(@max, varargin{:});
catch E
    throw(E);
end
end
