function a = mergecats(a,oldCategories,newCategory)
%

%   Copyright 2013-2024 The MathWorks, Inc.

if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',OLD,NEW'));
end

if isa(oldCategories,"pattern")
    if ~isscalar(oldCategories)
        error(message('MATLAB:categorical:InvalidNamesOrPattern','OLDCATEGORIES'));
    end
    oldCategories = a.categoryNames(matches(a.categoryNames,oldCategories));
else
    oldCategories = checkCategoryNames(oldCategories,1,'MATLAB:categorical:InvalidNamesOrPattern',{'OLDCATEGORIES'}); % remove any duplicates
end
isOrdinal = a.isOrdinal;

% Find the codes for the categories that will be merged. Ignore anything in
% oldCategories that didn't match a category in A.
[~,oldCodes] = ismember(oldCategories,a.categoryNames);
oldCodes(oldCodes == 0) = [];
if isempty(oldCodes), return, end

if nargin < 3
    newCategory = oldCategories{1};
elseif (ischar(newCategory) && isrow(newCategory)) || (isstring(newCategory) && isscalar(newCategory) && strlength(newCategory) > 0)
    newCategory = strtrim(newCategory);
    if matches(categorical.undefLabel,newCategory)
        error(message('MATLAB:categorical:mergecats:UndefinedLabel', categorical.undefLabel));
    elseif isempty(newCategory)
        error(message('MATLAB:categorical:mergecats:InvalidNewCategory'));
    end
else
    error(message('MATLAB:categorical:mergecats:InvalidNewCategory'));
end

% Set up a vector to map the existing categories to the new, merged categories.
acodes = a.codes;
anames = a.categoryNames;
convert = 1:cast(length(anames),'like',acodes);

% The merged category may be an existing category, or may be a new category.
newCode = find(matches(anames,newCategory)); % possibly empty
if isempty(newCode) || any(newCode==oldCodes)
    % Merging old categories to either a new category, or to one in that group.  The
    % merged category's internal code will reuse the lowest of the old codes.  Name
    % the merged category, with what may be a new or an old name.
    [newCode,j] = min(oldCodes); oldCodes(j) = [];
    anames{newCode} = char(newCategory);
else
    % Merging old categories to an existing category not in that group.  Already have
    % the internal code, and the name is already correct.
end

% Cannot merge nonconsecutive ordinal categories unless they're being merged to
% one in the middle.
if isOrdinal && any(diff(sort([oldCodes; newCode]))~=1)
    error(message('MATLAB:categorical:mergecats:NonconsecutiveCategories'));
end

% Remove the remaining old categories from A
anames(oldCodes) = [];
a.categoryNames = anames;

% Merge the codes for the old categories to the new category, and shift the
% codes for the existing categories down.
offset = zeros(size(convert),'like',acodes);
offset(oldCodes) = 1;
convert = convert - cumsum(offset);
convert(oldCodes) = convert(newCode);
convert = [categorical.undefCode convert]; % there may be undefined elements in a.codes
acodes = reshape(convert(acodes+1),size(acodes)); % acodes has correct type because convert does
a.codes = categorical.castCodes(acodes,length(anames)); % possibly downcast acodes
