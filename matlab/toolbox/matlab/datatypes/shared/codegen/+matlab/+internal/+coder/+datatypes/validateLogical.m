function paramVal = validateLogical(paramVal,paramName)  %#codegen
%VALIDATELOGICAL Validate a scalar logical input.

%   Copyright 2018-2019 The MathWorks, Inc.

coder.internal.assert(isscalar(paramVal) && (islogical(paramVal) || isnumeric(paramVal)), ...
    'MATLAB:table:InvalidLogicalVal', paramName);

    paramVal = logical(paramVal);
