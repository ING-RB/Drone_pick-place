function tf = isColon(s)   %#codegen
%ISCOLON Check if a subscript is ':'.
%   TF = ISCOLON(S) returns true if S is the scalar char ':' or the scalar
%   string ":". Otherwise ISCOLON returns false.

%   Copyright 2012-2019 The MathWorks, Inc.

% Check type first to reject 58 and {':'}.
tf = (ischar(s) || isstring(s)) && isscalar(s) && (s == ':');
