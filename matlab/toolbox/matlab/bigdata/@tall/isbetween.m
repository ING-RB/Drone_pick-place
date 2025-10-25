function tf = isbetween(varargin)
%ISBETWEEN Determine which elements are within specified range.
%   TF = ISBETWEEN(A,LOWER,UPPER)
%   TF = ISBETWEEN(A,LOWER,UPPER,INTERVALTYPE)
%
%   Limitations:
%   1. Input A must be a tall datetime, duration, or string array.
%   2. Name-value arguments "DataVariables" and "OutputFormat" are not
%   supported.
%
%   See also ISBETWEEN, DATETIME/ISBETWEEN, DURATION/ISBETWEEN.

%   Copyright 2016-2024 The MathWorks, Inc.

narginchk(3,4);
if nargin > 3
    % Convert intervalType to string
    intervalType = varargin{4};
    tall.checkNotTall(upper(mfilename), 3, intervalType);
    intervalType = tall.validateType(intervalType, upper(mfilename), ...
        {'char', 'string'}, 4);
    varargin{4} = string(intervalType);
end
varargin = cellfun(@iMaybeWrapChar, varargin, 'UniformOutput', false);
[varargin{1:nargin}] = tall.validateType(varargin{:}, upper(mfilename), ...
    {'datetime', 'duration', 'cellstr', 'string'}, 1:nargin);
tf = elementfun(@isbetween,varargin{:});
tf = setKnownType(tf, 'logical');
end

function x = iMaybeWrapChar(x)
% Convert character vector to cell
if ~istall(x) && ischar(x) && isrow(x)
    x = {x};
end
end
