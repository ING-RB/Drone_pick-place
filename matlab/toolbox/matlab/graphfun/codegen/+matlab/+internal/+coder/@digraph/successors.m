function sucid = successors(G, nodeid)
%

%   Copyright 2022 The MathWorks, Inc.
%#codegen

id = validateNodeID(G, nodeid);
coder.internal.assert(isscalar(id), 'MATLAB:graphfun:graphbuiltin:InvalidNodeScalar', G.numnodes);
sucid = successors(G.Underlying, id);
end