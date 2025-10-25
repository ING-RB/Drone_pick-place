function reset(ds)
%RESET   Reset all the underlying datastores to the start of data
%
%   See also: hasdata, read

%   Copyright 2022 The MathWorks, Inc.

ds.CurrentDatastoreIndex = 1;
for ii = 1:numel(ds.UnderlyingDatastores)
    reset(ds.UnderlyingDatastores{ii});
end
end