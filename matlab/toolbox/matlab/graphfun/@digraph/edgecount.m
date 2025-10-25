function c = edgecount(G, s, t)
%EDGECOUNT Determine number of edges between two nodes
%
%  C = EDGECOUNT(G,s,t) returns the number of edges from node s to node t.
%
%  See also FINDEDGE

%   Copyright 2017-2018 The MathWorks, Inc.

if xor(isnumeric(s), isnumeric(t))
    % Inputs s, t must be both numeric or both node names
    error(message('MATLAB:graphfun:findedge:InconsistentNodeNames'));
end

s = validateNodeID(G, s);
t = validateNodeID(G, t);

c = edgecount(G.Underlying, s, t);
