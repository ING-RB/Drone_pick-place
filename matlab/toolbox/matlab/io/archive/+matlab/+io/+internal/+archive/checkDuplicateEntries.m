function checkDuplicateEntries(entries, fcnName)
% Checks for duplicate entry names and removes 
% the duplicates from the entries struct.

% Copyright 2020 The MathWorks, Inc.
if ~isempty(entries)
    allNames = {entries.entry};
    [uniqueNames,i] = unique(allNames);
    if length(uniqueNames) < length(entries)
       firstDup = allNames{min(setdiff(1:length(entries),i))};
       eid = sprintf('MATLAB:%s:duplicateEntry',fcnName);
       error(eid, '%s', ...
           getString(message('MATLAB:io:archive:createArchive:duplicateEntry',upper(fcnName),firstDup)));
    end
end