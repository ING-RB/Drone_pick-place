function d = indegree(G, nodeids)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if nargin == 1
    d = indegree(G.Underlying);
else
    ids = validateNodeID(G, nodeids);
    d = indegree(G.Underlying, reshape(ids, size(nodeids)));
end
