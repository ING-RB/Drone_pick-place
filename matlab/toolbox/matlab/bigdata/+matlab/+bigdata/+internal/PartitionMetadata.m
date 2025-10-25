%PartitionMetadata
% An object that represents how a partitioned array has been partitioned.
%
% Properties:
%
%  Strategy:
%   The underlying partition strategy object that defines how the
%   execution environment will partition evaluation.
%
% Methods:
%
%  PartitionMetadata(strategy) constructs a metadata object from the given
%  strategy object. The strategy can be one of the following:
%   - a PartitionStrategy
%   - a datastore
%   - A numeric double scalar indicating desired number of partitions
%   - [] indicating arbitrary partitioning
%
% Static Methods:
%
%  obj = PartitionMetadata.vertcatPartitionMetadata builds partition
%  metadata that represents the vertical concatenation of all partitions
%  across all input partition strategies.
%
%  obj = align(varargin) align several partition metadata objects to form
%  one that will work for all the partitioned arrays.

%   Copyright 2016-2022 The MathWorks, Inc.
