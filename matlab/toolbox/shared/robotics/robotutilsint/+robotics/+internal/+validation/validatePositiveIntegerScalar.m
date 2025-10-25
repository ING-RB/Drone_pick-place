function out = validatePositiveIntegerScalar(in, fcnName, argName)
%This function is for internal use only. It may be removed in the future.

%validatePositiveIntegerScalar Validate the input is a positive integer and return as double type

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

    validateattributes(in, {'numeric'}, {'nonempty', 'scalar', 'real', ...
                                         'nonnan', 'finite', 'integer', 'positive'}, fcnName, argName);
    out = double(in);
end
