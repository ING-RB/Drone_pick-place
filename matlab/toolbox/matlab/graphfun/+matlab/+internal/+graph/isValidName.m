function tf = isValidName(s)
% ISVALIDNAME Checks if a char, cellstr or string contains valid node names.
%
% isValidNameType(s) && !isValidName(s) only happens if one of the names in
% s is empty, composed of all white space, or the missing string.
%
% Such names are not allowed as node names. Also, this method is used to
% check if a non-existing node name can be safely displayed in an error
% message.

% Copyright 2018-2022 The MathWorks, Inc.

if isstring(s)
    tf = ~any(ismissing(s), 'all');
else
    tf = (ischar(s) && isrow(s)) || (ischar(s) && isempty(s)) || iscellstr(s); %#ok<ISCLSTR> 
end

