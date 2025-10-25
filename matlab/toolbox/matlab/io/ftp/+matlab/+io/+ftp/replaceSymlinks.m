function listing = replaceSymlinks(listing, names)
%REPLACESYMLINKS Replace symbolic links with names

% Copyright 2020-2021 The MathWorks, Inc.
    names = sort(names);
    names(startsWith(names, ".")) = [];
    if ~isempty(names)
        [listing(:).("name")] = names{:};
    end
end