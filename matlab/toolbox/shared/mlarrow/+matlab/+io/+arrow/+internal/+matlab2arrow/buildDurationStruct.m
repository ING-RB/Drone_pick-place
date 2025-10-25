function [durationStruct, validStruct] = buildDurationStruct(durationArray)
%BUILDDURATIONSTRUCT
%   Builds the struct array used to represent duration arrays in the C++
%   layer.
%
% DURATIONSTRUCT is a scalar struct array.
%
% DURATIONSTRUCT contains the following fields: 
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------------------
% Values        char       Numeric array representing each duration in
%                          units of microseconds.
% Units         int64      Always set to 'microseconds'.
%
% VALIDSTRUCT is a scalar struct that represents DURATIONARRAY'S valid
% elements as a bit-packed logical array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.arrow.internal.matlab2arrow.buildValidStruct

    % Duration arrays are converted to an Arrow Time type.
    % Convert to the 64-bit microseconds type for balance between precision
    % and range.
    durationStruct.Values =  int64(milliseconds(durationArray) * 1e3);
    durationStruct.Units = 'microseconds';

    validStruct = buildValidStruct(durationArray);
end

