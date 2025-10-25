function out = isValidFunctionHandle(h)
%isValidFunctionHandle Determine whether the input value is a valid
%   function handle

%   Copyright 2018-2020 The MathWorks, Inc.

    out = isa(h, 'function_handle') || ...
        isa(h, 'matlab.settings.internal.FunctionDescriptor');
end

