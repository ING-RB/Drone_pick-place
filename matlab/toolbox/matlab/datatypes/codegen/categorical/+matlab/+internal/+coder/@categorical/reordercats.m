function b = reordercats(a,newOrder) %#codegen
%REORDERCATS Reorder categories in a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(nargout == 0,'MATLAB:categorical:NoLHS','REORDERCATS',',NEWORDER');

anames = a.categoryNames;
if coder.internal.isConst(size(anames))
    % Ensure anames is homogeneous
    coder.varsize('anames',[],[0 0]);
end

if nargin < 2 % put in alphabetic order
    [newCats,iconvert] = matlab.internal.coder.datatypes.cellstr_sort(anames);
    convert = zeros(length(newCats),1);
    convert(iconvert) = 1:length(newCats);   
elseif isnumeric(newOrder) % put in new order specified in permutation vector
    [tf,convert] = ismember((1:length(anames))', newOrder);
    coder.internal.assert(length(newOrder) == length(anames) && all(tf), ...
        'MATLAB:categorical:reordercats:InvalidNeworder');
    newCats = coder.nullcopy(cell(length(anames),1));
    for i = 1:length(anames)
        newCats{i} = anames{newOrder(i)};
    end
else % put in new order specified in category name vector
    newCats = a.checkCategoryNames(newOrder, 2); % error if duplicates
    [tf,convert] = matlab.internal.coder.datatypes.cellstr_ismember(anames, newCats);
    coder.internal.assert(length(newCats) == length(anames) && all(tf,'all'), ...
        'MATLAB:categorical:reordercats:InvalidNeworder');
end

convert = cast([0; convert(:)],'like',a.codes); % there may be zeros in a.codes

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.codes = reshape(convert(a.codes(:)+1), size(a.codes));
b.categoryNames = newCats;
