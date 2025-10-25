function remoteStore(id, entry)
%REMOTESTORE Add an entry to the ConstantStore for a given ID.

% Copyright 2022 The MathWorks, Inc.

store = parallel.internal.constant.ConstantStore.getInstance();
store.storeEntry(id, entry);

end