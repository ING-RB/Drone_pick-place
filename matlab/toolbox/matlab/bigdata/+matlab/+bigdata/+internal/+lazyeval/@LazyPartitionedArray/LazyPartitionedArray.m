%LazyPartitionedArray
% An implementation of the PartitionedArray interface that sits on top of
% the lazy evaluation architecture.
%
% How to construct:
%  pa = LazyPartitionedArray.createFromDatastore(ds) constructs a
%  LazyPartitionedArray representing the data underlying datastore ds.
%
%  pa = LazyPartitionedArray.createFromConstant(data) constructs a
%  LazyPartitionedArray representing the given data held on the client.  
%
% See PartitionedArray for more information on usage.

%   Copyright 2015-2022 The MathWorks, Inc.
