function remoteClearAll()
%REMOTECLEARALL Remove all entries. Does not throw.

% Copyright 2024 The MathWorks, Inc.

store = parallel.internal.constant.ConstantStore.getInstance();

ids = parallel.internal.constant.ConstantStore.getAll();
for idx = 1:numel(ids)
    id = ids{idx};
    entry = store.removeEntry(id);
    entry.cleanup();
end

end