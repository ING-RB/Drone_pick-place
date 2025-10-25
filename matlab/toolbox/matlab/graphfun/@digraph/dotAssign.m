function G = dotAssign(G, indexOp, V)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if strcmp(indexOp(1).Name, 'Edges')
    % Case G.Edges... = V
    indexOp = indexOp(2:end);
    G = assignToEdges(G, indexOp, V);
elseif strcmp(indexOp(1).Name, 'Nodes')
    % Case G.Nodes... = V
    indexOp = indexOp(2:end);
    G = assignToNodes(G, indexOp, V);
else
    % Case G.[someName]... = V, where [someName] is neither Nodes nor Edges.
    % Error (different message for private properties vs. nonexistent ones)
    mc = metaclass(G);
    if isempty( findobj(mc.PropertyList, '-depth',0,'Name', indexOp(1).Name) )
        error(message('MATLAB:noPublicFieldForClass', indexOp(1).Name, class(G)));
    else
        error(message('MATLAB:class:SetProhibited', indexOp(1).Name,  class(G)));
    end
end


function G = assignToEdges(G, indexOp, V)
if isempty(indexOp)
    % Do not allow assignment of edges here.
    error(message('MATLAB:graphfun:digraph:SetEdges'));
end

if indexOp(1).Type == matlab.indexing.IndexingOperationType.Dot
    % Case G.Edges.(somevar)... = V;
    varname = indexOp(1).Name;
    
    if strcmp(varname, 'EndNodes')
        error(message('MATLAB:graphfun:digraph:EditEdges'));
    elseif strcmp(varname, 'Properties')
        % Need to assign to Edges directly, so that the list of properties
        % is consistent with the Edges table.
        edges = getEdgesTable(G);
        
        % Call into table/*Assign with the remainder of the indexing
        edges.(indexOp) = V;
        
        edges(:, 'EndNodes') = [];
        G.EdgeProperties = edges;
        return;
    end
    
    edgeprop = G.EdgeProperties;
    if isnumeric(edgeprop) && strcmp(varname, 'Weight')
        % Case G.Edges.Weight... = V where edge properties are
        % minimized.
        G.EdgeProperties = []; % Make edgeprop reusable if possible.
        indexOp = indexOp(2:end);
        
        edgeprop = assignToEdgeWeightMinimized(edgeprop, indexOp, V, numedges(G.Underlying));
        
        G.EdgeProperties = edgeprop;
        return;
    end
    
    % Get Edge properties as a table, remove EdgeProperties to allow reuse.
    edgeprop = getEdgePropertiesTable(G);
    G.EdgeProperties = [];
    
    
else % G.Edges(...) = V or G.Edges{...} = V
    if numel(indexOp(1).Indices) == 2 % other numbers here result in error from table indexing
        % Case G.Edges(firstInd, secondInd) = V or G.Edges{firstInd, secondInd} = V
        % Error if first variable (EndNodes) is impacted, otherwise
        % modify j so that it can be applied to G.EdgeProperties.
        secondInd = indexOp(1).Indices{2};
        if isnumeric(secondInd)
            if any(secondInd == 1)
                error(message('MATLAB:graphfun:digraph:EditEdges'));
            end
        elseif islogical(secondInd) && ~isempty(secondInd)
            if secondInd(1)
                error(message('MATLAB:graphfun:digraph:EditEdges'));
            end
        elseif ischar(secondInd) || iscellstr(secondInd) || isstring(secondInd)
            if ismember('EndNodes', secondInd)
                error(message('MATLAB:graphfun:digraph:EditEdges'));
            elseif isequal(secondInd, ':')
                error(message('MATLAB:graphfun:digraph:EditEdges'));
            end
        end
    end
    
    % Get Edge properties as a table, remove EdgeProperties to allow reuse.
    edgeprop = getEdgePropertiesTable(G);
    G.EdgeProperties = [];

    % Pad edgeprop table with a first variable (will not be used, but
    % necessary to replicate table behavior, i.e., getting consistent
    % variable names from G.Edges(:, end+1) = V).
    edgeprop = [table(zeros(size(edgeprop, 1), 0)), edgeprop];
end

% Call into table/*Assign with the remainder of the indexing
edgeprop.(indexOp) = V;

if indexOp(1).Type ~= matlab.indexing.IndexingOperationType.Dot
    % Delete the padding variable representing EndNodes
    edgeprop(:, 1) = [];
end

% Number of rows must not change.
if size(edgeprop, 1) ~= numedges(G.Underlying)
    error(message('MATLAB:graphfun:digraph:SetEdges'));
end

% Something has been deleted, minimize if possible
if size(V, 1) == 0 && size(V, 2) == 0
    edgeprop = digraph.minimizeEdgeProperties(edgeprop);
end

% Remaining checks happen in set.EdgeProperties
G.EdgeProperties = edgeprop;


function G = assignToNodes(G, indexOp, V)

if isempty(indexOp)
    % Case G.Nodes = V;
    if size(V, 1) ~= numnodes(G)
        error(message('MATLAB:graphfun:digraph:SetNodes'));
    end
    V = digraph.validateNodeProperties(V);
    V = digraph.minimizeNodeProperties(V);
    G.NodeProperties = V;
else
    isMinimized = ~isobject(G.NodeProperties);
    if indexOp(1).Type == matlab.indexing.IndexingOperationType.Dot && ...
            strcmp(indexOp(1).Name, 'Name') && isMinimized
        % Case G.Nodes.Name... = V where G's Nodes are minimized
        % (only node names or no properties at all)
        nodeprop = G.NodeProperties;
        G.NodeProperties = [];
        indexOp = indexOp(2:end);
        
        nodeprop = assignToNodeNameMinimized(nodeprop, indexOp, V, numnodes(G.Underlying));
        
        G.NodeProperties = nodeprop;
    else
        % Case G.Nodes... = V, where we will treat Nodes as a generic
        % table.
        
        % Extract node properties as a table, and make it reusable
        nodeprop = getNodePropertiesTable(G);
        G.NodeProperties = [];
        
        % Call table/*Assign
        nodeprop.(indexOp) = V;
        
        % Number of rows must match number of nodes
        if size(nodeprop, 1) ~= numnodes(G)
            error(message('MATLAB:graphfun:digraph:SetNodes'));
        end
        
        % Input checking (check Name is valid, not needed if the assignment
        % was to another variable than Name)
        if ~(indexOp(1).Type == matlab.indexing.IndexingOperationType.Dot && ...
                ~strcmp(indexOp(1).Name, 'Name'))
            nodeprop = digraph.validateNodeProperties(nodeprop);
        end
        
        if isempty(V)
            % A variable was deleted, check if we can now minimize
            nodeprop = digraph.minimizeNodeProperties(nodeprop);
        end
        
        G.NodeProperties = nodeprop;
    end
end


function nodeprop = assignToNodeNameMinimized(nodeprop, indexOp, V, numNodes)
if isempty(indexOp)
    if isequal(V, [])
        % Remove node names.
        nodeprop = [];
        return;
    end
    nodeprop = V;
    if ischar(nodeprop)
        nodeprop = {nodeprop};
    end
else
    noNames = isequal(nodeprop, []);
    if noNames
        if isstring(V)
            nodeprop = string.empty;
        else
            nodeprop = {};
        end
    end
    
    nodeprop.(indexOp) = V;
    
    if isrow(nodeprop)
        nodeprop = nodeprop(:);
    end
end

if ~iscolumn(nodeprop)
    error(message('MATLAB:graphfun:digraph:NodesTableNameShape'));
elseif length(nodeprop) ~= numNodes
    error(message('MATLAB:graphfun:digraph:SetNodes'));
else
    nodeprop = digraph.validateName(nodeprop);
end


function edgeprop = assignToEdgeWeightMinimized(edgeprop, indexOp, V, numEdges)
if isempty(indexOp)
    if isequal(V, [])
        % Remove Weights from edge properties, resulting in
        % no edge properties.
        edgeprop = [];
        return;
    end
    edgeprop = V;
    % Match the error ID used from Edges table case
    if issparse(edgeprop) || ~isfloat(edgeprop) || isobject(edgeprop)
        error(message('MATLAB:graphfun:digraph:InvalidWeights'));
    end
else
    noWeights = isequal(edgeprop, []);
    if noWeights
        % Assigning single to non-existent Weight variable
        % should result in a single variable.
        edgeprop = zeros(0, 0, "like", V);
    end
    
    edgeprop.(indexOp) = V;
    
    if noWeights
        if isvector(edgeprop)
            % Assigning into part of a numeric table variable, remaining
            % rows are padded with zero.
            if length(edgeprop) < numEdges
                edgeprop(numEdges) = 0;
            end
        end
        if isrow(edgeprop)
            edgeprop = edgeprop(:);
        end
    end
end

if ~isreal(edgeprop)
    error(message('MATLAB:graphfun:digraph:InvalidWeights'));
elseif ~iscolumn(edgeprop) || numel(edgeprop) ~= numEdges
    error(message('MATLAB:graphfun:digraph:NonColumnWeights'));
end
