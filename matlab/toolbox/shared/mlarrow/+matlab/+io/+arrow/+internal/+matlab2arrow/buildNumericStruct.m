function [numericArray, validStruct] = buildNumericStruct(numericArray)
%BUILDNUMERICSTRUCT Validates numericArray is real and non-sparse and 
% creates a struct representating NUMERICARRAY's valid values.
%
% VALIDSTRUCT is a scalar struct that represents NUMERICARRAY'S valid
% elements as a bit-packed logical array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

% Copyright 2022 The MathWorks, Inc.

    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory
    import matlab.io.arrow.internal.matlab2arrow.buildValidStruct

    % numeric arrays must be real
    if ~isreal(numericArray)
        ExceptionFactory.throw(ExceptionType.ComplexNumber);
    end

    % numeric arrays must be non-sparse
    if issparse(numericArray)
        ExceptionFactory.throw(ExceptionType.SparseArray, class(numericArray))
    end

    % create the struct representation of the validity bitmap for
    % numericArray.
    validStruct = buildValidStruct(numericArray);
end

