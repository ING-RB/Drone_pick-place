function [files, numFilesPerDS] = getFiles(ds)

%   Copyright 2022-2023 The MathWorks, Inc.

filesListByDS = cell.empty(numel(ds.UnderlyingDatastores), 0);
numFilesPerDS = zeros(numel(ds.UnderlyingDatastores), 1);
try
    for idx = 1:numel(ds.UnderlyingDatastores)
        filesListByDS{idx} = getFiles(ds.UnderlyingDatastores{idx});
        numFilesPerDS(idx) = length(filesListByDS{idx});
    end
catch causeException
    msgid = "MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastoreGetFilesError";
    baseException = MException(msgid, message(msgid, idx));
    baseException = addCause(baseException, causeException);
    throwAsCaller(baseException);
end

files = vertcat(filesListByDS{:});

if isempty(files)
    error(message("MATLAB:io:datastore:write:write:NotBackedByFiles"));
end
end