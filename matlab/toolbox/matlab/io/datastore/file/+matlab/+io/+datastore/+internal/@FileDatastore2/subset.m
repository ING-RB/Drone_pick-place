function newds = subset(fds, indices)
%SUBSET   Create a new FileDatastore2 containing a subset of the input FileDatastore2.
%
%   SUBDS = subset(FDS, INDICES) returns a new FileDatastore2 SUBDS that contains
%   a subset of the data from the input FileDatastore2 FDS.
%
%   INDICES can be specified as a numeric or logical vector of indices.

%   Copyright 2022 The MathWorks, Inc.

    newfs = fds.FileSet.subset(indices);

    newds = fds.copy();
    newds.FileSet = newfs;
    newds.reset();
end