function err = remoteCleanup(id)
%REMOTECLEANUP Remove an entry from the ConstantStore for a given ID, and
%perform any cleanup actions. Return any errors so the client can handle
%them.

% Copyright 2023-2024 The MathWorks, Inc.

store = parallel.internal.constant.ConstantStore.getInstance();

% Check the ID is in this store before proceeding. The ID may
% not be in this store if something went wrong during the data
% transfer (e.g. disallowed classes for thread-based pools).
if ~store.isKey(id)
    err = MException.empty();
    return
end
entry = store.removeEntry(id);
err = entry.cleanup();
if ~isempty(err)
    try
        throw(err);
    catch err
    end
end
end