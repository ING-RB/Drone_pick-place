function obj = loadobj(s)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

if isfield(s, "EarliestSupportedVersion")
    % Error if we are sure that a version incompatibility is about to occur.
    if s.EarliestSupportedVersion > matlab.io.datastore.SequentialDatastore.ClassVersion
        error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
    end
end

% Reconstruct the object.
obj = matlab.io.datastore.SequentialDatastore();
obj.UnderlyingDatastores = s.UnderlyingDatastores;
obj.CurrentDatastoreIndex = s.CurrentDatastoreIndex;
obj.isFilesPartitionable = s.isFilesPartitionable;
end