%GETFUNCTIONHANDLE  Creates a function handle that represents the identity. 
%    The execution permission is granted based on the context.
% 
%    The creation of the function handle would be successful if the given identity
%    represents a top-level symbol that is permitted to execute in this context.
%
%    If the identity does not represent a top-level symbol, i.e., a class method, 
%    this function would throw UnableToTargetMethod error.
%
%    If there's no permission from the context to execute this symbol, this function 
%    would throw a NoPermissionToExecute error.
%
%    If the specified symbol is shadowed from the given context, and there's no way 
%    to use "import" to access that symbol, this function would throw a 
%    SymbolIsShadowed error.
%
%   Copyright 2024 The MathWorks, Inc.

function fh = functionHandle(context, identity)
    arguments (Input)
        context (1, 1) matlab.lang.internal.ExecutionContext
        identity (1, 1) {mustBeA(identity,["classID","matlab.lang.internal.SymbolID"])}
    end
    arguments (Output)
        fh (1, 1) function_handle
    end

    fh = context.functionHandleImpl(identity);
end