%CLASSESINNAMESPACE  Return a matlab.metadata.Class array describing all of the classes
%   visible to the specified namespace in the lookup context represented by context.
%
%   Copyright 2024 The MathWorks, Inc.

function metaclassArray = classesInNamespace(context, namespaceName)
    arguments (Input)
        context (1, 1) matlab.lang.internal.IntrospectionContext
        namespaceName (1, 1) string
    end
    arguments (Output)
        metaclassArray (1,:) matlab.metadata.Class
    end
    
    metaclassArray = context.classesInNamespaceImpl(namespaceName);
end