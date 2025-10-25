function ex = requiredWithinNamedException(functionName, pos, lineno)
%

%   Copyright 2019-2020 The MathWorks, Inc.

ex = MException('MATLAB:functionValidation:RequiredWithinNamed',...
    'Positional arguments cannot be put inside Named arguments block. At line %d of function %s positional argument %s appears inside a Named argument block.',...
    lineno, functionName, pos);
end
