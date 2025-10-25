function varargout = min(varargin)
%MIN Smallest component
%   M = MIN(X)
%   C = MIN(X,Y)
%   [M,I] = MIN(X)
%   [M,I] = MIN(X,[],DIM)
%   [M,I] = MIN(X,[],...,'linear')
%   M = MIN(...,NANFLAG)
%   C = MIN(...,"ComparisonMethod",METHOD)
%
%   Limitations:
%   Index output is not supported for tall tabular inputs.
%
%   See also: MIN, TALL.

%   Copyright 2015-2023 The MathWorks, Inc.

try
    [varargout{1:max(nargout,1)}] = minmaxop(@min, varargin{:});
catch E
    throw(E);
end
end
