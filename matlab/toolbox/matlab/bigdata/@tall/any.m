function out = any(x, varargin)
%ANY True if any element of a vector is nonzero or TRUE.
%
%   See also any.

% Copyright 2018 The MathWorks, Inc.

out = anyallop(@any, x, varargin{:});
