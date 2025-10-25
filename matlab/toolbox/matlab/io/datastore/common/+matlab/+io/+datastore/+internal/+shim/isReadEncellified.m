function tf = isReadEncellified(ds)
%isReadEncellified Compatibility layer for checking if read has already
% encellified non-uniform data.

%   Copyright 2017-2020 The MathWorks, Inc.

tf = false;
if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
    % if non-uniform data, only ImageDatastore can encellify
    % read data when ReadSize > 1.

    % check if the output of read is uniform
    uniformRead = matlab.io.datastore.internal.shim.isUniformRead(ds);

    tf = ~uniformRead && ~(~uniformRead && isa(ds, 'matlab.io.datastore.ImageDatastore') && ...
        isprop(ds, 'ReadSize') && isnumeric(ds.ReadSize) && ...
        ds.ReadSize > 1);
end
