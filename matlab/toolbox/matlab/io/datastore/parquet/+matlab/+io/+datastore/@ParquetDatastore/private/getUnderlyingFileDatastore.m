function [fds2, schds] = getUnderlyingFileDatastore(pds)
%getUnderlyingFileDatastore   Use the datastore visitor framework to get
%   the underlying FileDatastore2 in the composed datastore tree.

%   Copyright 2022 The MathWorks, Inc.

    fds2 = getUnderlyingDatastore(pds, "matlab.io.datastore.internal.FileDatastore2");
    schds = getUnderlyingDatastore(pds, "matlab.io.datastore.internal.SchemaDatastore");
end