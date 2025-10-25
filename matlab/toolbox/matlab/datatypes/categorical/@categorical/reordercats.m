function a = reordercats(a,newOrder)
%

%   Copyright 2013-2024 The MathWorks, Inc.

if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWORDER'));
end

if nargin < 2 % put in alphabetic order
    [newOrder,iconvert] = sort(a.categoryNames);
    convert(iconvert,1) = 1:length(newOrder);   
elseif isnumeric(newOrder) % put in new order specified in permutation vector
    [tf,convert] = ismember((1:length(a.categoryNames))', newOrder);
    if (length(newOrder) ~= length(a.categoryNames)) || ~all(tf)
        error(message('MATLAB:categorical:reordercats:InvalidNeworder'))
    end
    newOrder = a.categoryNames(newOrder);
elseif isa(newOrder,"pattern") % put in new order specificed by pattern vector
    if isempty(newOrder) && ~isempty(a.categoryNames)
        error(message('MATLAB:categorical:reordercats:InvalidNeworder'))
    end
    cats = a.categoryNames;
    pats = newOrder;
    newOrder = cell(1,numel(pats));
    for i = 1:numel(pats)
        newOrder{i} = find(matches(cats,pats(i)));
    end
    newOrder = unique(vertcat(newOrder{:}),"stable");
    [~,convert] = ismember((1:length(cats))', newOrder);
    if length(newOrder) ~= length(cats)
        error(message('MATLAB:categorical:reordercats:InvalidNeworder'));
    end
    newOrder = cats(newOrder);
else % put in new order specified in category name vector
    newOrder = checkCategoryNames(convertStringsToChars(newOrder), 2); % error if duplicates
    [tf,convert] = ismember(a.categoryNames, newOrder);
    if (length(newOrder) ~= length(a.categoryNames)) || ~all(tf)
        error(message('MATLAB:categorical:reordercats:InvalidNeworder'));
    end
end

convert = cast([0; convert(:)],'like',a.codes); % there may be zeros in a.codes
a.codes = reshape(convert(a.codes+1), size(a.codes));
a.categoryNames = newOrder(:);
