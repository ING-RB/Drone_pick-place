%FUNCTIONHANDLELOCATION represents the location (filepath and source positions)
% of a function_handle target.
% - functionHandle must be a function_handle.
% - args variable number of input. Must be provided to find an instance method
%   of an object.
function obj = FunctionHandleLocation(functionHandle, args)
    arguments(Input)
        functionHandle (1, 1) function_handle
    end
    arguments(Input, Repeating)
        args
    end
    arguments(Output)
        obj (1,1) matlab.lang.internal.FunctionHandleLocation
    end
    obj = matlab.lang.internal.FunctionHandleLocation.getFunctionHandleLocation(functionHandle, args{:});
end