function n = neighbors(G, nodeid)
%

%   Copyright 2021-2022 The MathWorks, Inc.
%#codegen

id = validateNodeID(G, nodeid);
coder.internal.assert(isscalar(id), 'MATLAB:graphfun:graphbuiltin:InvalidNodeScalar', G.numnodes);
n = neighbors(G.Underlying, id);
end
