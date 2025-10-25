function cleanupOldCacheEntries(cacheEntryKeys)
% Cleanup CacheEntryKey instances that are referenced by the OldId of
% another. These instances are to be replaced as per the contract of
% updateforreuse.

%   Copyright 2022 The MathWorks, Inc.

oldIds = vertcat(cacheEntryKeys.OldId, string.empty());
if ~isempty(oldIds)
    ids = vertcat(cacheEntryKeys.Id, string.empty());
    isOld = ismember(ids, oldIds);
    oldKeys = cacheEntryKeys(isOld);
    for ii = 1:numel(oldKeys)
        oldKeys(ii).markInvalid();
    end
end
end
