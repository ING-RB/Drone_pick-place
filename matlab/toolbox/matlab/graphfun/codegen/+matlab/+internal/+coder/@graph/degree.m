function d = degree(G, nodeids)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if nargin==1
    d = degree(G.Underlying);
else
    ids = validateNodeID(G, nodeids);
    d = degree(G.Underlying, reshape(ids, size(nodeids)));
end