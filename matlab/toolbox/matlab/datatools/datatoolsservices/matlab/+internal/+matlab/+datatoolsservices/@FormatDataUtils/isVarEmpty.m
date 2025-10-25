% Returns true if the variable is empty.  Wrapper for the builtin function.

% Copyright 2015-2023 The MathWorks, Inc.

function b = isVarEmpty(var)
    b = builtin('isempty', var);
end
