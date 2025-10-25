function a = removecats(a,oldCategories)
%

%   Copyright 2013-2024 The MathWorks, Inc.

if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',OLD'));
end

if nargin < 2
    % Find any unused codes in A.
    codehist = histc(a.codes(:),1:length(a.categoryNames)); %#ok<HISTC>
    oldCodes = find(codehist == 0);
else
    if isa(oldCategories,"pattern")
        if ~isscalar(oldCategories)
            error(message('MATLAB:categorical:InvalidNamesCharOrPattern','OLDCATEGORIES'));
        end
        oldCategories = a.categoryNames(matches(a.categoryNames,oldCategories));
    else
        oldCategories = checkCategoryNames(oldCategories,1,'MATLAB:categorical:InvalidNamesCharOrPattern',{'OLDCATEGORIES'}); % remove any duplicates
    end
    
    % Find the codes for the categories that will be dropped.
    [tf,oldCodes] = ismember(oldCategories,a.categoryNames);

    % Ignore anything in oldCategories that didn't match a category of A.
    oldCodes = oldCodes(tf);
    
    % Some elements of A may have become undefined.
end

% Set up a vector to map the existing categories to the new, reduced categories.
acodes = a.codes;
anames = a.categoryNames;
convert = 1:cast(length(anames),'like',acodes);

% Remove the old categories from A.
anames(oldCodes) = [];
a.categoryNames = anames(:);

% Translate the codes for the categories that haven't been dropped.
dropped = zeros(size(convert),'like',acodes);
dropped(oldCodes) = 1;
convert = convert - cumsum(dropped);
convert(dropped>0) = categorical.undefCode;
convert = [categorical.undefCode convert]; % there may be undefined elements in a.codes
acodes = reshape(convert(acodes+1),size(acodes)); % acodes has correct type because convert does
a.codes = categorical.castCodes(acodes,length(anames)); % possibly downcast acodes
