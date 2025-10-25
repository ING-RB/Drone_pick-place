function ok = isDataOfClass(data, classList)
% Check if some input data is of one of the listed classes, with correct
% expansion of compound types like 'numeric', 'float', 'cellstr', etc.
%
%  OK = ISDATAOFCLASS(DATA, CLASSLIST) returns true if the class of DATA is
%  one of the entries in CLASSLIST, false otherwise. If CLASSLIST is empty,
%  all classes are assumed to be allowed. For CELLSTR the elements of the
%  data are examined to ensure all are chars.
%
%
%  Examples:
%  >> ok = isDataOfClass(int32(1), {'numeric', 'datetime'}) % = true
%  >> ok = isDataOfClass(true, {'numeric', 'datetime'}) % = false
%
%  See also: isClassOneOf

% Copyright 2018-2023 The MathWorks, Inc.

actualClass = class(data);
ok = ismember(actualClass, classList) || ...
     (ismember('numeric', classList) && isnumeric(data)) || ...
     (ismember('cellstr', classList) && iscellstr(data)) || ...
     (ismember('integer', classList) && isinteger(data)) || ...
     (ismember('float', classList)   && isfloat(data)) || ...
     (ismember('pattern', classList) && isa(data, "pattern")); %#ok<ISCLSTR>
end

