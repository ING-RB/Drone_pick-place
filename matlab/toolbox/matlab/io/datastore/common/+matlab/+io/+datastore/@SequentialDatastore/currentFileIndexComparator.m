function tf = currentFileIndexComparator(ds, currFileIndex)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

tf = false; %#ok<NASGU>

% Populate the files list per underlying datastore and use it to find the
% datastore position and granular index of the currFileIndex in it.
[~, numFilesPerDS] = getFiles(ds);
[dsIndex, granularFileIndex] = getDSIndexAndGranularFileIndex(numFilesPerDS, currFileIndex);

% If dsIndex is not same as CurrentDatastoreIndex, currFileIndex which is
% the index of the file written by datastore is in the previous underlying
% datastore and so return false.
tf = (dsIndex == ds.CurrentDatastoreIndex);

% If dsIndex is same as CurrentDatastoreIndex, to handle "ReadSize" not
% "file" cases, compare the file index of file read from the datastore to
% granularFileIndex which is the index of file corresponding to
% currFileIndex, the index of the file written by datastore. If same, then
% "ReadSize" might not be "file".
if tf
    tf = currentFileIndexComparator(ds.UnderlyingDatastores{dsIndex}, granularFileIndex);
end
end