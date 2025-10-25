function logicalArray = buildLogical(logicalStruct, nullIndices, opts)
%BUILDLOGICAL
%   Builds creates logical arrays from bit-packed uint8 arrays.
%
%
% ARROW_LOGICAL_STRUCT is an 1xN struct.
% 
% ARROW_LOGICAL_STRUCT contains the follow fields: 
% 
% Field Name    Class      Description
% ----------    ------     ----------------------------
% Data          uint8      bitpacked data    
% Length        double     Length of the data once unpacked
% ArrowType     char       Either 'buffer' or 'logical'

%   Copyright 2021 The MathWorks, Inc.

    arguments
        logicalStruct % arrow2matlab validates the struct's fields
        nullIndices logical
        opts.LogicalTypeConversionOptions (1, 1) matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions();
    end

    import matlab.io.arrow.internal.arrow2matlab
    import matlab.io.arrow.internal.arrow2matlab.handleNullLogicals

    logicalArray = arrow2matlab(logicalStruct);
    logicalArray = handleNullLogicals(logicalArray, nullIndices,...
        LogicalTypeConversionOptions=opts.LogicalTypeConversionOptions);
end
