function ok = isClassOneOf(clz, classList)
% Check if an input class is one of the listed classes, with correct
% expansion of compound types like 'numeric', 'float', etc.
%
%  OK = ISCLASSONEOF(CLZ, CLASSLIST) returns true if the class name CLZ is one
%  of the entries in CLASSLIST, false otherwise. If CLASSLIST is empty, all
%  classes are assumed to be allowed.
%
%
%  Examples:
%  >> ok = isClassOneOf('int32', {'numeric', 'datetime'}) % = true
%  >> ok = isClassOneOf('logical', {'numeric', 'datetime'}) % = false
%
%  See also: isDataOfClass

% Copyright 2016-2022 The MathWorks, Inc.

clz = string(clz);

if isempty(classList)
    ok = true(size(clz));
    return
end

integerTypes = ["int8", "int16", "int32", "int64", ...
                "uint8", "uint16", "uint32", "uint64"];
floatTypes   = ["single", "double"];
if ismember("numeric", classList)
    classList = [ classList, integerTypes, floatTypes ];
end
if ismember("integer", classList)
    classList = [ classList, integerTypes ];
end
if ismember("float", classList)
    classList = [ classList, floatTypes ];
end
if ismember("cellstr", classList)
    classList = [ classList, "cell" ];
end
ok = ismember(clz, classList);
end
