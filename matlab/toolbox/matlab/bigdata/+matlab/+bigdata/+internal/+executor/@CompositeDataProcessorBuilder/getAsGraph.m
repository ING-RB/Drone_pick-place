function g = getAsGraph(obj)
% Retrieve a digraph object that represents the graph of
% underlying builders.

%   Copyright 2023-2024 The MathWorks, Inc.

if isempty(obj.Graph)
    obj.buildGraph();
end
g = obj.Graph;
% The cached digraph has weak references back to this object to avoid cyclic
% dependencies, we convert those references back to strong as those are what
% are expected by the caller.
g.Nodes.Builder = arrayfun(@(b) b.Handle, g.Nodes.Builder);
end
