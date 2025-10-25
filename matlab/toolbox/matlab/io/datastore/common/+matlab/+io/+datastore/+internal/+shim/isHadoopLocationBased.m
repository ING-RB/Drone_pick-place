function tf = isHadoopLocationBased(ds)
%isHadoopLocationBased Compatibility layer for checking for Hadoop support

%   Copyright 2018-2019 The MathWorks, Inc.

ds = matlab.io.datastore.internal.shim.unwrapTransforms(ds);
if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
    tf = isa(ds, 'matlab.io.datastore.mixin.HadoopFileBasedSupport') ...
        && ~( isa(ds, 'matlab.io.datastore.MatSeqDatastore') && strcmpi(ds.FileType, 'mat') );
elseif isa(ds, 'matlab.io.datastore.internal.FrameworkDatastore')
    tf = ds.IsHadoopLocationBased;
else
    tf = isa(ds, 'matlab.io.datastore.HadoopFileBased') || isa(ds, 'matlab.io.datastore.HadoopLocationBased');
end
