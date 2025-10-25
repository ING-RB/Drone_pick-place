%STR@FUNC  Construct a function handle to the function name "name" in the specified context.
%   Note that the context is used for name resolution only, not for workspaces variables.
%   The create of the function handle will always be successful.
%
%   Copyright 2024 The MathWorks, Inc.

function fh = str2func(context, name) 
    arguments (Input)
        context (1, 1) matlab.lang.internal.ExecutionContext
        name {mustBeTextScalar}
    end
    arguments (Output)
        fh (1, 1) function_handle
    end

    fh = context.str2funcImpl(name);
end