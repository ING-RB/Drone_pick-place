function [logicalStruct, validStruct] = buildLogicalStruct(logicalArray)
%BUILDLOGICALSTRUCT
%   Builds the struct array used to represent logical arrays in the C++
%   layer. Logical arrays are represented as bit-packed uint8 arrays.
%
% LOGICALARRAY is a logical array.
%
% LOGICALSTRUCT is a scalar struct array.
%
% LOGICALSTRUCT contains the following fields: 
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------------------
% Values        uint8      Bit-packed representation of the logical array. 
% Length        double     Length of the original array.
% ArrowType     char       Always set to 'buffer'.
%
% VALIDSTRUCT is a scalar struct that represents LOGICALARRAYS'S valid
% elements as a bit-packed logical array. Because there is no concept of a
% missing logical value, VALIDSTRUCT's Values field is always a 0x1
% uint8 array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory
    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical

    if issparse(logicalArray)
        ExceptionFactory.throw(ExceptionType.SparseArray, "logical");
    end

    % Logical variables are bit-packed for usage by the Arrow layer.
    logicalStruct = bitPackLogical(logicalArray);
    logicalStruct.Length = length(logicalArray);

    validStruct = bitPackLogical(false(0, 0));
end