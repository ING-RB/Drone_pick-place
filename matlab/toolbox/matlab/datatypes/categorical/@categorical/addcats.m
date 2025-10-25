function a = addcats(a,newCategories,varargin)
%

%   Copyright 2013-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isCharString

if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEW,...'));
end

% Remove any duplicates in the new names, both within them and between them and
% the existing names, but leave the non-duplicates in their original order.
categories = a.categoryNames;
numExisting = length(categories);
newCategories = setdiff(checkCategoryNames(newCategories,0),categories,'stable');
numNew = length(newCategories);
if numExisting+numNew > categorical.maxNumCategories
    error(message('MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories));
end

if nargin < 3
    if isordinal(a)
        error(message('MATLAB:categorical:addcats:NoBeforeOrAfter'));
    end
    % Add the new categories onto the end of existing list.
    after = numExisting;
    categories = [categories; newCategories];
else
    pnames = {'Before' 'After'};
    dflts =  {     {}      {} };
    [before,after,supplied] = ...
        matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:}); %#ok<*PROP>
    [before,after] = convertStringsToChars(before,after);
    if supplied.Before
        if supplied.After
            error(message('MATLAB:categorical:addcats:BeforeAndAfter'));
        elseif ~isCharString(before)
            error(message('MATLAB:categorical:addcats:InvalidCategoryName','BEFORE'));
        end
        ibefore = find(matches(categories,before));
        if isempty(ibefore)
            error(message('MATLAB:categorical:addcats:UnrecognizedCategory',before));
        end
        after = ibefore - 1;
        categories = [categories(1:after); newCategories; categories(after+1:end)];
    elseif supplied.After
        if ~isCharString(after)
            error(message('MATLAB:categorical:addcats:InvalidCategoryName','AFTER'));
        end
        iafter = find(matches(categories,after));
        if isempty(iafter)
            error(message('MATLAB:categorical:addcats:UnrecognizedCategory',after));
        end
        after = iafter;
        categories = [categories(1:after); newCategories; categories(after+1:end)];
    else
        after = numExisting;
        categories = [categories; newCategories];
    end
end

% Possibly upcast a's codes in advance to account for new categories
a.codes = categorical.castCodes(a.codes,length(categories));
a.categoryNames = categories;
if after < numExisting
    shift = (a.codes > after);
    a.codes(shift) = a.codes(shift) + numNew;
end
