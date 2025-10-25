function d = outdegree(G, nodeids)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if nargin == 1
    d = outdegree(G.Underlying);
else
    ids = validateNodeID(G, nodeids);
    d = outdegree(G.Underlying, reshape(ids, size(nodeids)));
end
