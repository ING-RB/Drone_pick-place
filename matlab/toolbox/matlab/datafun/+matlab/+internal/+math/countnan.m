function count = countnan(x,varargin)
%countnan Returns the number of NaNs in the input
%
%   C = countnan(X,DIM) returns the number of nans in X along the specified
%   dimension DIM
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2024 The MathWorks, Inc.

narginchk(1,2);
if ~isnumeric(x) && ~islogical(x) && ~ischar(x) && ~istabular(x)
    error(message("MATLAB:countnan:invalidTypeFirstInput"));
end

% Objects should use the SUM branch, unless they are subclasses of a built
% in numeric/logical/char array.
if ~isobject(x) || isa(x, "numeric") || isa(x, "logical") ||  isa(x, "char")
    count = matlab.internal.math.countnanBuiltin(x,varargin{:});
else
    count = sum(ismissing(x), varargin{:});
end
end