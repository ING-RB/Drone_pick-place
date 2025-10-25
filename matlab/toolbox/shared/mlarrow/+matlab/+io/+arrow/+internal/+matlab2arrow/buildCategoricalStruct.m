function [categoricalStruct, validStruct] = buildCategoricalStruct(categoricalArray)
%BUILDCATEGORICALSTRUCT
%     Decomposes categorical data into a numeric values array and
%     an mxStruct array representing category names.
%
% NOTE: Categorical variables are decomposed into a numeric array of
% contiguous UTF-8 code units and another uint32 array of offsets
% locating the start of each string in the UTF-8 array.
% 
% CATEGORICALARRAY is a Nx1 categorical array.
%
% CATEGORICALSTRUCT is a scalar struct array.
%
% CATEGORICALSTRUCT contains the following fields:
%
% Field Name    Class       Description
% ----------    -------     -----------------------------------------------
% Values        integer     Numeric representation of the categories. The 
%                               smallest integer type required to represent
%                               each category is used.
% Categories    struct      Represents the category names.
% Ordinal       logical     Represents if the categorical array is ordinal.
%
% VALIDSTRUCT is a scalar struct that represents CATEGORICALARRAY'S valid
% elements as a bit-packed logical array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.


%   Copyright 2021-2022 The MathWorks, Inc.

    import matlab.io.arrow.internal.convertUTF16ToUTF8
    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical

    % convert categorical indices to the smallest possible numeric array.
    c = categories(categoricalArray);
    numCategories = length(c);
    if numCategories <= intmax("int8")
        numericValues = int8(categoricalArray);
    elseif numCategories <= intmax("int16")
        numericValues = int16(categoricalArray);
    elseif numCategories <= intmax("int32")
        numericValues = int32(categoricalArray);
    else
        numericValues = int64(categoricalArray);
    end
    
    % shift categorical values down by one to account for Arrow's
    % zero-based indexing of dictionary arrays.
    numericValues = numericValues - 1;
    
    % convert category names to UTF-8 compatible format.
    [categoryNames.Values, categoryNames.StartOffsets] = ...
        convertUTF16ToUTF8(string(c));
    
    categoricalStruct.Values = numericValues;
    categoricalStruct.Categories = categoryNames;
    categoricalStruct.Ordinal = isordinal(categoricalArray);

    % Always bit-pack categorical arrays due to ARROW-2462.
    validStruct = bitPackLogical(~ismissing(categoricalArray));
end

