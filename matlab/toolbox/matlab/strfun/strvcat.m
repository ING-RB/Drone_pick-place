function s=strvcat(varargin)
%

%   Copyright 1984-2023 The MathWorks, Inc.

[varargin{:}] = convertStringsToChars(varargin{:});

numinput = nargin;
if numinput == 1 && iscellstr(varargin{1})
  varargin = (varargin{1});
end
% find the empty cells 
notempty = ~cellfun('isempty',varargin);
% vertically concatenate the non-empty cells.
s = char(varargin{notempty});
