function tf = isCharRowType(val, allowempty)
% Check whether input is a char row. Input can be an
% array or a coder type. 

% Copyright 2020 The MathWorks, Inc.

if nargin < 2
    allowempty = true;
end

if isa(val, 'coder.Type')
    tf = strcmp(val.ClassName, 'char') && val.SizeVector(1) == 1 && ...
        ~val.VariableDims(1) && (allowempty || val.SizeVector(2) > 0);
else
    tf = ischar(val) && isrow(val) && (allowempty || ~isempty(val));
end