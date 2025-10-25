function ind = findnode(G, N)
%FINDNODE Determine node ID given a name
%   ind = FINDNODE(G, nodeID) returns the numeric nodeID of the node with
%   name nodeID. nodeID may be a numeric node ID, a character vector, 
%   a string vector, or a cell array of character vectors. If there is no
%   node corresponding to nodeID in G, ind is zero.
%
%   Example:
%       % Create a graph, and then find the numeric indices for two
%       % node names.
%       s = {'AA' 'AA' 'AA' 'AB' 'AC' 'BB'};
%       t = {'BA' 'BB' 'BC' 'BA' 'AB' 'BC'};
%       G = graph(s,t);
%       G.Nodes
%       k = findnode(G,{'AB' 'BC'})
%
%   See also GRAPH, NUMNODES, FINDEDGE

%   Copyright 2014-2021 The MathWorks, Inc.

if isnumeric(N)
    N = N(:);
    if ~isreal(N) || any(fix(N) ~= N) || any(N < 1)
        error(message('MATLAB:graphfun:findnode:PosInt'));
    end
    ind = double(N);
    ind(ind > numnodes(G)) = 0;
elseif matlab.internal.graph.isValidNameType(N)
    [names, hasNodeNames] = getNodeNames(G);
    if ~hasNodeNames
        error(message('MATLAB:graphfun:findnode:NoNames'));
    end

    if isscalar(N) || ischar(N)
        ind = find(strcmp(N, names));
        if isempty(ind)
            ind = 0;
        end
    else
        [~,ind] = ismember(N(:), names);
    end
else
    error(message('MATLAB:graphfun:findnode:ArgType'));
end
