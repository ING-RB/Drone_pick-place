%FUNCTIONSINNAMESPACE  Return a matlab.metadata.Function array describing all of the
%    functions visible to the specified namespace in the lookup context represented by context.
%
%   Copyright 2024 The MathWorks, Inc.

function metaclassArray = functionsInNamespace(context, namespaceName)
    arguments (Input)
        context (1, 1) matlab.lang.internal.IntrospectionContext
        namespaceName (1, 1) string
    end
    arguments (Output)
        metaclassArray (1,:) matlab.internal.metadata.Function
    end

    metaclassArray = context.functionsInNamespaceImpl(namespaceName);
end