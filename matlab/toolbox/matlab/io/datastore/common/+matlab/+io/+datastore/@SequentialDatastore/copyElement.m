function cpObj = copyElement(ds)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

cpObj = copyElement@matlab.mixin.Copyable(ds);

% Deep copy each of the underlying datastores
for idx = 1:numel(ds.UnderlyingDatastores)
    ds.UnderlyingDatastores{idx} = copy(ds.UnderlyingDatastores{idx});
end
end