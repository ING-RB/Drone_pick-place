function tf = hasMarkForReuse(varargin)
%hasMarkForReuse Has a given tall array been marked for reuse?
%
%  Syntax:
%   tf = matlab.bigdata.internal.util.hasMarkForReuse(X1,X2,..) returns
%   true if all of X1,X2,.. have already been marked for reuse or has
%   already been gathered and so is already effective marked for reuse.
%   This will also return true for tall arrays that are derived from cached
%   data, as long as all operations are simple.

% Copyright 2018 The MathWorks, Inc.

isPartitioned = false(size(varargin));
for ii = 1:nargin
    % Unwrap tall inputs
    if istall(varargin{ii})
        varargin{ii} = hGetValueImpl(varargin{ii});
    end
    % Unwrap grouped inputs
    if isa(varargin{ii}, 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
        [~, varargin{ii}] = ungroup(varargin{ii}, ...
            matlab.bigdata.internal.UnknownEmptyArray.build());
    end
    % We only parse the input if is a an actual partitioned array that
    % hasn't yet been completed.
    isPartitioned(ii) = isa(varargin{ii}, 'matlab.bigdata.internal.PartitionedArray');
end
varargin(~isPartitioned) = [];

closureGraph = matlab.bigdata.internal.optimizer.ClosureGraph(varargin{:});
g = closureGraph.Graph;
g = reordernodes(g, toposort(g));


nodes = g.Nodes;
names = string(nodes.Name);
opTypeVector = nodes.OpType;
isClosureVector = nodes.IsClosure;

% A flag per node that will store whether that node is based on data that
% has been marked for reuse.
hasMarkForReuseVector = false(numnodes(g), 1);

% Calculate distances matrix up-front to make calculating predecessor nodes more
% efficient.
dist = distances(g);

for ii = 1:numnodes(g)
    % Equivalent to 'predecessors(g, ii)' - but faster.
    previousNodes = dist(:, ii) == 1;
    
    isInputMarkForReuse = all(hasMarkForReuseVector(previousNodes));
    
    opType = string(opTypeVector(ii));
    if isClosureVector(ii)
        if opType == "ReadOperation" ...
                || opType == "RepartitionOperation" ...
                || opType == "AggregateByKeyOperation"
            hasMarkForReuseVector(ii) = false;
        elseif opType == "CacheOperation" ...
                || opType == "ReduceOperation" ...
                || opType == "NonPartitionedOperation"
            hasMarkForReuseVector(ii) = true;
        else
            hasMarkForReuseVector(ii) = isInputMarkForReuse;
        end
    else
        hasMarkForReuseVector(ii) = isInputMarkForReuse;
    end
end

tf = true;
for ii = 1:numel(varargin)
    tf = tf && hasMarkForReuseVector(varargin{ii}.ValueFuture.IdStr == names);
end
end
