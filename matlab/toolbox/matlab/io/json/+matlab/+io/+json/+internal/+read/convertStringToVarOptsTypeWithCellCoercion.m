function result = convertStringToVarOptsTypeWithCellCoercion(str, varopts)
%

%   Copyright 2024 The MathWorks, Inc.

    result = matlab.io.json.internal.read.convertStringToHomogeneousType(str, varopts);

    result = num2cell(result);
end
