function b = isstring( o, strs )
%ISSTRING  b = ISSTRING( obj, S ) true if nodes have string S
%   S may be a string or a cell array of strings
%ISSTRING  b = ISSTRING( obj ) behaves the same as the built-in string,
%   return false because mtree is not a string array.

% Copyright 2006-2018 The MathWorks, Inc.

  if nargin > 1
    strs = convertStringsToChars(strs);
  end
  if nargin == 1
    b = false;
  else
    found = mtfind(o, 'String', strs);
    b = found.IX(o.IX);
  end
end
