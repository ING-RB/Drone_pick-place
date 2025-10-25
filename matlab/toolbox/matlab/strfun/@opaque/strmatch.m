function i = strmatch(str,strs,flag)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if (nargin < 3)
  i = strmatch(fromOpaque(str),fromOpaque(strs));
else
  i = strmatch(fromOpaque(str),fromOpaque(strs),fromOpaque(flag));
end
