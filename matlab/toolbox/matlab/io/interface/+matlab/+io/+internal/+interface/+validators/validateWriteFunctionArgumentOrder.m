function validateWriteFunctionArgumentOrder(data, ...
                                            filename, ...
                                            writeFunctionName, ...
                                            expectedDataType, ...
                                            expectedDataTypeFcn)
%VALIDATEWRITEFUNCTIONARGUMENTORDER Errors if the arguments passed to one of the
% WRITE<TYPE> functions are in reverse order.
% In other words:
% WRITE<TYPE>(filename, data) instead of WRITE<TYPE>(data, filename).

%   Copyright 2019-2022 The MathWorks, Inc.

    if matlab.internal.datatypes.isScalarText(data) && expectedDataTypeFcn(filename)
        me = MException(message('MATLAB:table:write:IncorrectArgumentOrder', ...
                        writeFunctionName, expectedDataType));
        throwAsCaller(me);
    end
end
