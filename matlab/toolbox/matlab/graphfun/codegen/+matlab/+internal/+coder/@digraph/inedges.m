function [edgeid, n] = inedges(G, nodeid)
%

%   Copyright 2022 The MathWorks, Inc.
%#codegen

id = validateNodeID(G, nodeid);
coder.internal.assert(isscalar(id), 'MATLAB:graphfun:graphbuiltin:InvalidNodeScalar', G.numnodes);
[edgeidInt,nInt] = inedges(G.Underlying, id);
n = double(nInt.');
edgeid = double(edgeidInt.');