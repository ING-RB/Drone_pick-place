function tf = isScalarStringType(val)
% Check whether input is a scalar string. Input can be an
% array or a coder type. 

% Copyright 2020 The MathWorks, Inc.
if isa(val, 'coder.Type')
    tf = strcmp(val.ClassName, 'string') && all(val.SizeVector == 1) && ...
        all(~val.VariableDims);
else
    tf = isstring(val) && isscalar(val);
end