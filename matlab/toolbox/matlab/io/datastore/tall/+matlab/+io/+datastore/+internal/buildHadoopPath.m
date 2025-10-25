function pth = buildHadoopPath(location)
%BUILDHADOOPPATH Build a Hadoop Path object that represents the given location.

%   Copyright 2017-2018 The MathWorks, Inc.
location = matlab.io.datastore.internal.buildHadoopIri(location);
hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
pth = hdfsLoader.newPath(java.net.URI(location));
