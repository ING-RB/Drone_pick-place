function durationArray = buildDuration(durationStruct, nullIndices)
%BUILDDURATION
%   Builds a duration array from an arrow::Time32 or arrow::Time64 array
% 
% STRUCTARRAY is a scalar struct array.
%
% STRUCTARRAY contains the following fields:
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------
% Units         char       Species the unit of time.
% Values        numeric    Numeric time values.

%   Copyright 2021 The MathWorks, Inc.
    arguments
        durationStruct (1, 1) struct {mustBeDurationStruct}
        nullIndices logical
    end

    import matlab.io.arrow.internal.arrow2matlab.timeUnitsToMultiplier


    multiplier = timeUnitsToMultiplier(durationStruct.Units);
    durationArray = seconds(double(durationStruct.Values) / multiplier);

    durationArray(nullIndices) = missing;
end

function mustBeDurationStruct(durationStruct)
    import matlab.io.arrow.internal.validateStructFields
    requiredFields = ["Values", "Units"];
    validateStructFields(durationStruct, requiredFields);
end
