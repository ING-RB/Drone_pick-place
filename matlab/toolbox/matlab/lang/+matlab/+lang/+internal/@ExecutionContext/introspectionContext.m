%INTROSPECTIONCONTEXT  Return the associated matlab.lang.internal.IntrospectionContext 
%   to this matlab.lang.internal.ExecutionContext
%
%   Copyright 2024 The MathWorks, Inc.

function ic = introspectionContext(context)
    arguments (Input)
        context (1, 1) matlab.lang.internal.ExecutionContext
    end
    arguments (Output)
        ic (1, 1) matlab.lang.internal.IntrospectionContext
    end

    ic = context.introspectionContextImpl();
end