function [nodeProperties, newnodes] = addToNodeProperties(G, N, checkN)
%ADDTONODEPROPERTIES Private utility function for ADDNODE and ADDEDGE
%
%    See also ADDNODE, ADDEDGE

%   Copyright 2017-2022 The MathWorks, Inc.

if nargin < 3
    checkN = true;
end

[names, hasNodeNames] = getNodeNames(G);

if matlab.internal.graph.isValidNameType(N)
    if ~matlab.internal.graph.isValidName(N)
        error(message('MATLAB:graphfun:digraph:InvalidNames'));
    end
    if ischar(N)
        N = {N};
    else
        N = cellstr(N);
    end
    newnodes = numel(N);
    nodeProperties = G.NodeProperties;
    if ~hasNodeNames
        names = makeNodeNames(numnodes(G), 0);
    end
    % In all cases, names is now a cellstr with the node names of G
    if checkN || ~hasNodeNames
        N = digraph.validateName(N(:));
        if any(ismember(N, names))
            error(message('MATLAB:graphfun:digraph:NonUniqueNames'));
        end
    else
        N = N(:);
    end
    
    if isa(nodeProperties, 'table')
        nodeProperties.Name = names;
        nodeProperties.Name(end+1:end+newnodes,1) = N; % Also grows rest of the table.
    else
        nodeProperties = names;
        nodeProperties(end+1:end+newnodes,1) = N;
    end
elseif isnumeric(N) && isscalar(N)
    nodeProperties = G.NodeProperties;
    if ~isreal(N) || fix(N) ~= N || N < 0 || ~isfinite(N)
        error(message('MATLAB:graphfun:addnode:InvalidNrNodes'));
    end
    if hasNodeNames
        newNodeNames = makeNodeNames(N, numnodes(G));
        if any(ismember(newNodeNames, names))
            error(message('MATLAB:graphfun:addnode:NonUniqueDefaultNames'));
        end
        if iscell(nodeProperties)
            nodeProperties(end+1:end+N,1) = newNodeNames;
        else
            nodeProperties.Name(end+1:end+N,1) = newNodeNames;
        end
    else
        if ~hasNodeProperties(G)
            % No node properties exist, none need adding.
        else
            % Increase length of nodeProperties, filling in the same values
            % as table indexing does when a new row is added at end+2 and
            % the end+1 row needs to be filled.
            nodeProperties = matlab.internal.datatypes.lengthenVar(nodeProperties, numnodes(G)+N);
        end
    end
    newnodes = N;
elseif istable(N)
    nodeProperties = getNodePropertiesTable(G);
    N = digraph.validateNodeProperties(N);
    if hasNodeNames && matlab.internal.graph.hasvar(N, "Name")
        Nname = N.Name;
        npName = nodeProperties.Name;
        if any(ismember(Nname, npName))
            error(message('MATLAB:graphfun:digraph:NonUniqueNames'));
        end
    end
    nodeProperties = [nodeProperties; N];
    newnodes = size(N,1);
else
    error(message('MATLAB:graphfun:addnode:SecondInput'));
end

function C = makeNodeNames(numNodes, firstVal)
if numNodes > 0
    C = cellstr([repmat('Node', numNodes, 1) ...
        num2str(firstVal+(1:numNodes)', '%-d')]);
else
    C = cell(0,1);
end
