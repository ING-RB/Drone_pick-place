function b = mergecats(a,oldCats,newCat) %#codegen
%MERGECATS Merge categories in a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(nargout == 0,'MATLAB:categorical:NoLHS','MERGECATS',',OLD,NEW');

oldCategories = categorical.checkCategoryNames(oldCats,1); % remove any duplicates
isOrdinal = a.isOrdinal;

anames = a.categoryNames;
if coder.internal.isConst(size(anames)) 
    % Ensure anames is homogeneous
    coder.varsize('anames',[],[0 0]);
end

% Find the codes for the categories that will be merged. Ignore anything in
% oldCategories that didn't match a category in A.
isOldCode = matlab.internal.coder.datatypes.cellstr_ismember(anames, oldCategories);
oldCodes = reshape(find(isOldCode),[],1);

if ~any(isOldCode)
    % If oldCats did not match any existing category, return the input as it is.
    bcodes = a.codes;
    bnames = a.categoryNames;
else
    if nargin < 3
        newCategory = oldCategories{1};
    else
        coder.internal.assert((ischar(newCat) && isrow(newCat)) || (isstring(newCat) && isscalar(newCat) && strlength(newCat) > 0),...
            'MATLAB:categorical:mergecats:InvalidNewCategory');
        newCategory = strtrim(newCat);
        coder.internal.errorIf(strcmp(categorical.undefLabel,newCategory),...
            'MATLAB:categorical:mergecats:UndefinedLabel', categorical.undefLabel);
        coder.internal.errorIf(isempty(newCategory),...
            'MATLAB:categorical:mergecats:InvalidNewCategory');
    end

    % Set up a vector to map the existing categories to the new, merged categories.
    acodes = a.codes;
    convert = 1:cast(length(anames),'like',acodes);

    % The merged category may be an existing category, or may be a new category.
    newCode = matlab.internal.coder.datatypes.scanLabels(newCategory,anames);

    if newCode == 0 || any(newCode==oldCodes)
        % Merging old categories to either a new category, or to one in that group.  The
        % merged category's internal code will reuse the lowest of the old codes.  Name
        % the merged category, with what may be a new or an old name.
        [newCode,j] = min(oldCodes); 
        isOldCode(oldCodes(j)) = false;
        oldCodes(j) = [];
    else
        % Merging old categories to an existing category not in that group.  Already have
        % the internal code, and the name is already correct.
    end

    % Cannot merge nonconsecutive ordinal categories unless they're being merged to
    % one in the middle.
    coder.internal.errorIf(isOrdinal && any(diff(sort([oldCodes; newCode]))~=1),...
        'MATLAB:categorical:mergecats:NonconsecutiveCategories');

    % Remove the remaining old categories from A
    bnames = coder.nullcopy(cell(length(anames) - nnz(isOldCode),1));
    idx = 1;
    for i = 1:length(anames)
        if ~isOldCode(i)
            if i == newCode
                bnames{idx} = char(newCategory);
            else
                bnames{idx} = anames{i};
            end
            idx = idx + 1;
        end
    end

    % Merge the codes for the old categories to the new category, and shift the
    % codes for the existing categories down.
    offset = zeros(size(convert),'like',acodes);
    offset(oldCodes) = 1;
    convert = convert - cumsum(offset);
    convert(oldCodes) = convert(newCode);
    convert = [categorical.undefCode convert]; % there may be undefined elements in a.codes
    bcodes = reshape(convert(acodes(:)+1),size(acodes)); % acodes has correct type because convert does
end

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.codes = categorical.castCodes(bcodes,length(bnames)); % possibly downcast acodes
b.categoryNames = bnames;
