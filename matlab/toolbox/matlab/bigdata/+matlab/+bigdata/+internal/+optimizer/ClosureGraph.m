%ClosureGraph An execution graph leading up to a series of partitioned arrays.
%   The primary purpose of this class is to compute a digraph of
%   closure/promise/future nodes and the connectivity between them. This
%   information can then be used by optimizers to discover optimization
%   opportunities.
%
% Properties:
%  Graph: digraph linking Nodes with Edges.
%
% Methods:
%  obj = ClosureGraph(varargin) builds a closure graph from the given
%  LazyPartitionedArray objects.
%
%  recalculate(obj) recalculates the graph from scratch.
%

% Copyright 2016-2022 The MathWorks, Inc.
