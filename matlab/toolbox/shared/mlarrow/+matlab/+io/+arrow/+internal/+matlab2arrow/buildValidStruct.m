function validStruct = buildValidStruct(array)
%BUILDVALIDSTRUCT 
% Builds a struct array to represent which elements in the ARRAY are valid,
% i.e. not missing or null. The valid indices are stored in a bit-packed
% uint8 array.
%
% NOTE: If the array contains zero missing values, VALIDSTRUCT'S Values
% field is empty, signifying each element in ARRAY is valid.
%
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical

    missingValues = ismissing(array);    

    if any(missingValues)
        validStruct = bitPackLogical(~missingValues);
    else
        validStruct = bitPackLogical(false(0, 0));
    end
end

