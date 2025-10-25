function H = addnode(G, N)
%

%#codegen
%   Copyright 2021 The MathWorks, Inc.

H = G;
[H.NodeProperties, newnodes] = G.addToNodeProperties(N);

if newnodes > 0
    % Update underlying
    nrNodes = numnodes(G) + newnodes;
    ed = H.Underlying.Edges;
    H.Underlying = G.underlyingConstructor(ed(:, 1), ed(:, 2), nrNodes);
end

if nargout < 1
    coder.internal.compileWarning('MATLAB:graphfun:rmnode:NoOutput');
end
