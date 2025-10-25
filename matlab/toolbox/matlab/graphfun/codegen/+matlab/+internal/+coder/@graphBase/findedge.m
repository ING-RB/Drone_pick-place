function [sOut, tOut] = findedge(G, s, t)
%

%#codegen
%   Copyright 2021 The MathWorks, Inc.

if nargin == 1
    coder.internal.assert(nargout == 2, 'MATLAB:graphfun:findedge:minLHS');
    e = G.Underlying.Edges;
    sOut = e(:,1);
    tOut = e(:,2);
elseif nargin == 2
    coder.internal.assert(nargout == 2, 'MATLAB:graphfun:findedge:minLHS');
    % Return s/t given an index
    coder.internal.assert(isnumeric(s),'MATLAB:graphfun:findedge:nonNumericEdges');
    s = reshape(s, [], 1); % This is needed to prevent size mismatches when s can be empty
    ne = numedges(G);    
    coder.internal.assert(isreal(s),'MATLAB:graphfun:codegen:ComplexNodeID');
    for ii = coder.internal.indexInt(1) : numel(s)
        currentS = s(ii);
        coder.internal.assert(fix(currentS) == currentS && ...
            currentS >= 1 && currentS <= ne, ...
            'MATLAB:graphfun:findedge:EdgeBounds',ne);
    end
    e = G.Underlying.Edges(s,:);
    sOut = e(:, 1);
    tOut = e(:, 2);
else
    % Return an index given s/t
    coder.internal.assert(isnumeric(s) == isnumeric(t), ...
        'MATLAB:graphfun:findedge:InconsistentNodeNames');

    s = validateNodeID(G, s);
    t = validateNodeID(G, t);
    
    if nargout <= 1
        sOut = G.Underlying.findedge(s, t);
    else
        [sOut, tOut] = G.Underlying.findedge(s, t);
    end
end
