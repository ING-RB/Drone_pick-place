function data = getFirstNonEmptyPreview(ds)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

idx = 1;
while ~hasdata(ds.UnderlyingDatastores{idx})
    idx = idx+1;
end

firstNonEmptyUnderlyingDS = ds.UnderlyingDatastores{idx};

data = preview(firstNonEmptyUnderlyingDS);
% G2805978: preview() should return the same type as read. Hence, wrap in
% cell in case of non-uniform preview data as we do this for all
% SequentialDatastore reads.
data = matlab.io.datastore.internal.read.iMakeUniform(data, firstNonEmptyUnderlyingDS);
end