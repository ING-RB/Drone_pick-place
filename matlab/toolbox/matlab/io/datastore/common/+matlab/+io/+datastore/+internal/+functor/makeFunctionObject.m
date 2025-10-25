function value = makeFunctionObject(value)
%makeFunctionObject   Returns a matlab.mixin.internal.FunctionObject
%   if the input is either a function_handle or a FunctionObject.
%
%   If the input is neither of these types, this function will throw an
%   error.
%
%   See also: matlab.io.datastore.internal.functor.FunctionHandleFunctionObject

%   Copyright 2022 The MathWorks, Inc.

    classes = ["function_handle" "matlab.mixin.internal.FunctionObject"];
    attributes = "scalar";
    validateattributes(value, classes, attributes);

    % Convert function_handle to a FunctionObject subclass.
    import matlab.io.datastore.internal.functor.FunctionHandleFunctionObject
    if isa(value, "function_handle")
        value = FunctionHandleFunctionObject(value);
    end
end
