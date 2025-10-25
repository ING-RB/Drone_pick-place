function b = renamecats(a,oldCats,newCats) %#codegen
%RENAMECATS Rename categories in a categorical array.

%   Copyright 2020 The MathWorks, Inc.

if nargout == 0
    coder.internal.errorIf(nargin<3,'MATLAB:categorical:NoLHS','RENAMECATS',',NEWNAMES')
    coder.internal.errorIf(nargin>=3,'MATLAB:categorical:NoLHS','RENAMECATS',',OLDNAMES,NEWNAMES');
end

% Initialize the output and copy everything except category names
b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.codes = a.codes;
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;

oldNames = a.checkCategoryNames(convertStringsToChars(oldCats),2); % error if duplicates

if nargin < 3
    coder.internal.assert(length(oldNames) == length(a.categoryNames), ...
        'MATLAB:categorical:renamecats:IncorrectNumNames');
    b.categoryNames = oldNames;
else
    newNames = a.checkCategoryNames(convertStringsToChars(newCats),2); % error if duplicates
    coder.internal.assert(length(newNames) == length(oldNames), ...
        'MATLAB:categorical:renamecats:IncorrectNumNamesPartial');
    
    [tf,locs] = matlab.internal.coder.datatypes.cellstr_ismember(oldNames,a.categoryNames);
    coder.internal.assert(all(tf,'all'),'MATLAB:categorical:renamecats:InvalidNames');
    
    notlocs = true(size(a.categoryNames)); notlocs(locs) = false;
    
    % Error if any of the remaining category names matches newNames
    for i = 1:length(a.categoryNames)
        if notlocs(i)
            dupIdx = matlab.internal.coder.datatypes.scanLabels(a.categoryNames{i},newNames);
            coder.internal.assert(dupIdx == 0,'MATLAB:categorical:renamecats:DuplicateNames',oldNames{dupIdx},newNames{dupIdx});
        end
    end
    
    bCategoryNames = coder.nullcopy(cell(length(notlocs),1));
    % Assign newNames to the locations where the corresponding oldNames were present 
    for i = 1:length(locs)
        bCategoryNames{locs(i)} = newNames{i};
    end
    % Get the unchanged category names from a.categoryNames
    for i = 1:length(notlocs)
        if notlocs(i)
            bCategoryNames{i} = a.categoryNames{i};
        end
    end
    
    b.categoryNames = bCategoryNames;
end