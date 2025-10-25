function s = saveobj(ds)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

% Store save-load metadata.
s = struct("EarliestSupportedVersion", 1);
s.ClassVersion = ds.ClassVersion;

% Public properties
s.UnderlyingDatastores = ds.UnderlyingDatastores;
s.SupportedOutputFormats = ds.SupportedOutputFormats;

% Private properties
s.CurrentDatastoreIndex = ds.CurrentDatastoreIndex;
s.isFilesPartitionable = ds.isFilesPartitionable;
end