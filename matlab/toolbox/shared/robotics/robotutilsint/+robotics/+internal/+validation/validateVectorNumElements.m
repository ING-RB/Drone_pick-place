function validVec = validateVectorNumElements(inVec, length, fcnName, argName)
%This function is for internal use only. It may be removed in the future.

%validateVectorNumElements Validate the length of the input vector and return it as a row vector

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

    validateattributes(inVec, {'numeric'}, {'nonempty', 'real', 'nonnan', 'finite', 'vector', 'numel', length}, fcnName, argName);
    validVec = double(inVec(:).');

end
