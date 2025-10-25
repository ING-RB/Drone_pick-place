function tf = isValidNameType(s)
% ISVALIDNAMETYPE Checks if s has the correct type to specify node names.
%
% Node names can be specified as a char, cellstr or string. This is a
% quick check that does not look at the content of s.
%
% If it is a char vector, this must be either a row vector or be empty.
% The same applies for each char vector element of a cellstr.

% Copyright 2018-2020 The MathWorks, Inc.

requireCell = true;
allowEmpty = true;

if isnumeric(s)
    tf = false;
else
    tf = (matlab.internal.datatypes.isCharStrings(s, requireCell, allowEmpty)) ...
        || isstring(s) || (ischar(s) && (isrow(s) || isempty(s)) );
end
