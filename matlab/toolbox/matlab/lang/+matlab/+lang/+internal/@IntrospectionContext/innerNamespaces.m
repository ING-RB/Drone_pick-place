%INNERNAMESPACES Return a string array describing all of the inner namespace 
%   visible to the specified namespace in the lookup context represented by context
%
%   Copyright 2024 The MathWorks, Inc.

function nsNames = innerNamespaces(context, namespaceName)
    arguments (Input)
        context (1, 1) matlab.lang.internal.IntrospectionContext
        namespaceName (1, 1) string
    end
    arguments (Output)
        nsNames (1,:) string
    end

    nsNames = context.innerNamespacesImpl(namespaceName);
end