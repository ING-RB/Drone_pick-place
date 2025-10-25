function b = removecats(a,oldCats) %#codegen
%REMOVECATS Remove categories from a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(nargout == 0,'MATLAB:categorical:NoLHS','REMOVECATS',',OLD');

anames = a.categoryNames;
if coder.internal.isConst(size(anames))
    % Ensure anames is homogeneous
    coder.varsize('anames',[],[0 0]);
end

if nargin < 2
    % Find any unused codes in A.
    codehist = histc(a.codes(:),1:length(a.categoryNames));
    isOldCode = codehist == 0;
    oldCodes = find(isOldCode);
else
    oldCategories = a.checkCategoryNames(oldCats,1); % remove any duplicates
    
    % Find the locations of codes for the categories that will be dropped.
    isOldCode = matlab.internal.coder.datatypes.cellstr_ismember(anames,oldCategories);

    % Get the indices of names that matched category names in A, ignore
    % anything else.
    oldCodes = find(isOldCode);
    
    % Some elements of A may have become undefined.
end

% Set up a vector to map the existing categories to the new, reduced categories.
bcodes = a.codes;
bnames = coder.nullcopy(cell(length(anames)-nnz(isOldCode),1));
convert = 1:cast(length(anames),'like',bcodes);
% Fill output category names with the remaining categories.
idx = 1;
for i = 1:length(anames)
    if ~isOldCode(i)
        bnames{idx} = anames{i};
        idx = idx + 1;
    end
end

% Translate the codes for the categories that haven't been dropped.
dropped = zeros(size(convert),'like',bcodes);
dropped(oldCodes) = 1;
convert = convert - cumsum(dropped);
convert(dropped>0) = categorical.undefCode;
convert = [categorical.undefCode convert]; % there may be undefined elements in a.codes
bcodes = reshape(convert(bcodes(:)+1),size(bcodes)); % acodes has correct type because convert does


b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.codes = categorical.castCodes(bcodes,length(bnames)); % possibly downcast acodes
b.categoryNames = bnames;