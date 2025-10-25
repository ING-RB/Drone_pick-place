function s=str2mat(varargin)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

s = char(varargin{:});
