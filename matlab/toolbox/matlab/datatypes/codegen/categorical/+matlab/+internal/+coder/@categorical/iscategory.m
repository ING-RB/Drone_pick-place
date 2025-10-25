%#codegen
function tf = iscategory(a,s)
%ISCATEGORY Test for categorical array categories.
%   TF = ISCATEGORY(A,CATEGORIES) returns a logical array the same size
%   CATEGORIES, containing logical 1 (true) where the corresponding element
%   of CATEGORIES is a category in the categorical array A, and logical 0
%   (false) otherwise.  CATEGORIES is a string array, a cell array of
%   character vectors, or a character vector.
%
%   A need not contain any elements that have values from CATEGORIES
%   for ISCATEGORY to return true.
%
%   See also CATEGORIES, ADDCATS, REMOVECATS, MERGECATS, RENAMECATS, REORDERCATS,
%            SETCATS, ISMEMBER, UNIQUE.

%   Copyright 2018-2021 The MathWorks, Inc.

% Call checkCategoryNames with no outputs because we only need
% error-checking and checkCategoryNames does an unwanted reshape.
categorical.checkCategoryNames(s,false);
tf = matlab.internal.coder.datatypes.cellstr_ismember(...
    matlab.internal.coder.datatypes.cellstr_strtrim(s),a.categoryNames); % might be the function, or the categorical method
