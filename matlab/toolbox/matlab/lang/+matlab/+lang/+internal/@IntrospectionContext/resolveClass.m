%RESOLVECLASS  Look up the class identity for className in the specified context
%    cid = resolveClass(context, className) returns the classID representing 
%    className in introspection context context.
%
%    An empty 0x0 classID array is returned if the class name does not exist 
%    in the specified context. Returns an empty 0x0 classID
%
%   Copyright 2024 The MathWorks, Inc.

function cid = resolveClass(context, className)
    arguments (Input)
        context (1,1) matlab.lang.internal.IntrospectionContext
        className {mustBeTextScalar}
    end
    arguments(Output)
        cid (1,1) classID
    end

    cid = context.resolveClassImpl(className);
end