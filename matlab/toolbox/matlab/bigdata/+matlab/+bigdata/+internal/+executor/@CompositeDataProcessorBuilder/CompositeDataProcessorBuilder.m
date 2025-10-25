%CompositeDataProcessorBuilder
% A helper class that builds a graph of DataProcessor instances and wraps
% them in a CompositeDataProcessor.
%
% To construct a CompositeDataProcessor, the caller must build up a graph
% of CompositeDataProcessorBuilder instances. Then, the caller must call
% feval on the final or most downstream builder, which will return a
% CompositeDataProcessor representing the graph of everything upstream.
%
% Properties:
%  Id:
%    A unique ID for this builder.
%
%  InputBuilders:
%    An array of CompositeDataProcessorBuilder instances that
%    represent the direct inputs to the DataProcessorFactory held by
%    this instance.
%
%  DataProcessorFactory;
%    A factory that will construct a data processor or empty. If
%    non-empty, this will be used to construct one of the data
%    processor instances inside the CompositeDataProcessor built by
%    this class.
%
%  NumOutputPartitions:
%    Number of output partitions expected from the underlying data
%    processor. This is passed to the data processor factory function.
%    This can be empty.
%
%  InputOrdinal:
%    The 1-based input ordinal corresponding to this node. This is only set
%    if the node represents a global input bound by position. I.E. The
%    corresponding node of CompositeDataProcessor will emit one positional
%    input argument of the parent CompositeDataProcessor/feval.
%
%  InputId:
%    The input ID string corresponding to this node. This is only set if
%    the node represents a global input not yet bound. I.E. The
%    corresponding node of CompositeDataProcessor will emit one input
%    argument of the parent CompositeDataProcessor/feval, with which
%    argument chosen to be decided once all input ID strings are known. See
%    AllInputIds for the mapping between input ID strings and positional
%    input arguments.
%
%  AllInputIds;
%    An ordered array of all InputId values that will represent the
%    list of dependency inputs to the constructed CompositeDataProcessor.
%
%  IsGlobalInput;
%    Whether this Builder contains only an input node.
%
% Methods:
%
%  processor = feval(obj, partition, varargin)
%    Build the graph of DataProcessors and wrap them in an enclosing
%    CompositeDataProcessor.

%   Copyright 2015-2023 The MathWorks, Inc.
