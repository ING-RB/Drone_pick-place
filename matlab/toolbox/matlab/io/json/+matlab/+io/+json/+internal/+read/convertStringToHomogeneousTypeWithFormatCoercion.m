function result = convertStringToHomogeneousTypeWithFormatCoercion(str, varopts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    [result, info] = convertStringToHomogeneousType(str, varopts);

    if any(info.Errors)
        % Recursively call this function till all the Errors are resolved.
        result(info.Errors) = convertStringToHomogeneousTypeWithFormatCoercion(str(info.Errors), varopts);
    end
end
