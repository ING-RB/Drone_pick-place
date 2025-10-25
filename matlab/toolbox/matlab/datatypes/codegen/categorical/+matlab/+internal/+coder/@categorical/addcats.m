function b = addcats(a,newCategories,varargin)%#codegen
%ADDCATS Add categories to a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(nargout == 0,'MATLAB:categorical:NoLHS','ADDCATS',',NEW,...');
coder.internal.errorIf(nargin < 2,'MATLAB:minrhs');

% Remove any duplicates in the new names, both within them and between them and
% the existing names, but leave the non-duplicates in their original order.
categories = a.categoryNames;
numExisting = length(categories);
newCats = removeExistingCats(categorical.checkCategoryNames(convertStringsToChars(newCategories),0),categories);
numNew = length(newCats);

coder.internal.errorIf(numExisting+numNew > categorical.maxNumCategories, 'MATLAB:categorical:MaxNumCategoriesExceeded', categorical.maxNumCategories);

if nargin < 3
    coder.internal.errorIf(isordinal(a),'MATLAB:categorical:addcats:NoBeforeOrAfter')
    % Add the new categories onto the end of existing list.
    after = numExisting;
else
    pnames = {'Before' 'After'};
    poptions = struct( ...
        'CaseSensitivity',false, ...
        'PartialMatching','unique', ...
        'StructExpand',false);
    supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});
    
    before = convertStringsToChars(coder.internal.getParameterValue(supplied.Before,{},varargin{:}));
    after = convertStringsToChars(coder.internal.getParameterValue(supplied.After,{},varargin{:}));
    
    if supplied.Before
        coder.internal.errorIf(supplied.After ~= 0, ...
            'MATLAB:categorical:addcats:BeforeAndAfter');
        coder.internal.errorIf(~matlab.internal.coder.datatypes.isCharString(before), ...
            'MATLAB:categorical:addcats:InvalidCategoryName','BEFORE');

        ibefore = matlab.internal.coder.datatypes.scanLabels(before,categories);
        
        coder.internal.errorIf(ibefore == 0, ...
            'MATLAB:categorical:addcats:UnrecognizedCategory',before);
        
        after = ibefore - 1;
    elseif supplied.After
        coder.internal.errorIf(~matlab.internal.coder.datatypes.isCharString(after), ...
            'MATLAB:categorical:addcats:InvalidCategoryName','AFTER');
        
        iafter = matlab.internal.coder.datatypes.scanLabels(after,categories);
        
        coder.internal.errorIf(iafter == 0, ...
            'MATLAB:categorical:addcats:UnrecognizedCategory',after);

        after = iafter; 
    else
        after = numExisting;
    end
end

bCategoryNames = insertAfter(categories,newCats,after);
% Possibly upcast a's codes in advance to account for new categories
bCodes = categorical.castCodes(a.codes,length(bCategoryNames));
if after < numExisting
    shift = (bCodes > after);
    % Update the codes identified by shift. Use an explicit for-loop instead of
    % doing it in a vectorized fashion to avoid potential runtime eml size check
    % error
    for i = 1:numel(shift)
        if shift(i)
            bCodes(i) = bCodes(i) + numNew;
        end
    end
end

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.codes = bCodes;
b.categoryNames = bCategoryNames;
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
end

function uniqueCats = removeExistingCats(newCats, existingCats)
% Helper to remove any existing or duplicate category names from newCats

    % Remove any duplicates amongst the new categories
    uniqueNewCats = matlab.internal.coder.datatypes.cellstr_unique(newCats,'stable');
    
    % Scan the inputs to identify unique new category names
    uniqueIdx = false(length(uniqueNewCats),1);
    for i = 1:length(uniqueNewCats)
        if sum(strcmp(uniqueNewCats{i},existingCats)) == 0
            uniqueIdx(i) = true;
        end
    end
    
    uniqueCats = matlab.internal.coder.datatypes.cellstr_parenReference(uniqueNewCats, uniqueIdx);
end

function out = insertAfter(oldCats, newCats, after)
% Helper to insert new category names into a list of old category names after a
% given index.

    len = numel(oldCats) + numel(newCats);
    out = cell(len,1);
    numNew = numel(newCats);
    for i = 1:len
        if i <= after
            out{i} = oldCats{i};
        elseif i <= after+numNew
            out{i} = newCats{i-after};
        else
            out{i} = oldCats{i-numNew};
        end
    end
end