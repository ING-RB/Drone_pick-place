function categoricalArray = buildCategorical(categoricalStruct, nullIndices)
%BUILDCATEGORICAL
%  Build categorical array from indices and categories arrays.
%
% STRUCT_ARRAY is a scalar struct.
%
% STRUCT_ARRAY contains the following fields:
%
% Field Name    Class         Description
% ----------    --------      ------------------------------------
% Categories    anything      string array representing 
%                               the category names.
% Values        int32         numeric array from which to create 
%                               the categorical array.
% Ordinal       logical       Indicates whether if the categorical
%                               array is ordinal.

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        categoricalStruct (1, 1) struct {mustBeCategoricalStruct}
        nullIndices logical
    end

    categories = categoricalStruct.Categories;
    categoricalArray = categorical(categoricalStruct.Values,...
        0:length(categories)-1,categories, 'Ordinal', categoricalStruct.Ordinal);

    categoricalArray(nullIndices) = missing;
end

function mustBeCategoricalStruct(categoricalStruct)
    import matlab.io.arrow.internal.validateStructFields
    requiredField = ["Values", "Ordinal"];
    validateStructFields(categoricalStruct, requiredField);
end
