function tf = iscategory(a,categories)
%

%   Copyright 2013-2024 The MathWorks, Inc.

if isa(categories,"pattern")
    tf = false(size(categories));
    for i = 1:numel(categories)
        tf(i) = any(matches(a.categoryNames,categories(i)));
    end
else
    % Call checkCategoryNames with no outputs because we only need
    % error-checking and checkCategoryNames does an unwanted reshape.
    checkCategoryNames(categories,false,'MATLAB:categorical:InvalidNamesCharOrPattern',{'CATEGORIES'});
    tf = ismember(strtrim(categories),a.categoryNames); % might be the function, or the categorical method
end
