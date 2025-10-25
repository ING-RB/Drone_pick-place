function tf = isConvertibleToFunctionObject(input)
%isConvertibleToFunctionObject   Returns true if the input is a FunctionObject or a function_handle.
%
%   See also: matlab.io.datastore.internal.functor.FunctionHandleFunctionObject

%   Copyright 2022 The MathWorks, Inc.

    tf = isa(input, "function_handle") ...
      || isa(input, "matlab.mixin.internal.FunctionObject");
end