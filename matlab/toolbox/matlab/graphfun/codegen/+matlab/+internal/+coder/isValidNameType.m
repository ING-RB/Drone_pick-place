function tf = isValidNameType(s)
% ISVALIDNAMETYPE Checks if s has the correct type to specify node names.

% Copyright 2021 The MathWorks, Inc.
%#codegen

coder.inline('always');
tf = isstring(s) || (ischar(s) && isrow(s)) || (ischar(s) && isempty(s)) || iscellstr(s);
