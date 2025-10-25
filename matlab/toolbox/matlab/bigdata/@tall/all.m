function out = all(x, varargin)
%ALL True if all elements of a vector are nonzero or TRUE.
%
%   See also all.

% Copyright 2018 The MathWorks, Inc.

out = anyallop(@all, x, varargin{:});
