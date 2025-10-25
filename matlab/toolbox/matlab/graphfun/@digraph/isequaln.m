function tf = isequaln(g1, g2, varargin)
% 

%   Copyright 2020 The MathWorks, Inc.

if nargin > 2
    % Deal with the (rare) case of more than two inputs by calling
    % this function again with each input separately.
    tf = isequaln(g1, g2);
    ii = 1;
    while tf && ii <= nargin-2
        tf = isequaln(g1, varargin{ii});
        ii = ii+1;
    end
    return;
end

% Check that both inputs are of type digraph
if ~isa(g1, 'digraph') || ~isa(g2, 'digraph')
    tf = false;
    return;
end

% Check internal graph
if ~isequaln(g1.Underlying, g2.Underlying)
    tf = false;
    return;
end

% Check node properties
nodeprop1 = g1.NodeProperties;
nodeprop2 = g2.NodeProperties;
if isobject(nodeprop1)
    nodeprop2 = getNodePropertiesTable(g2);
elseif isobject(nodeprop2)
    nodeprop1 = getNodePropertiesTable(g1);
end
if ~isequaln(nodeprop1, nodeprop2)
    tf = false;
    return;
end

% Check edge properties
edgeprop1 = g1.EdgeProperties;
edgeprop2 = g2.EdgeProperties;
if isobject(edgeprop1)
    edgeprop2 = getEdgePropertiesTable(g2);
elseif isobject(edgeprop2)
    edgeprop1 = getEdgePropertiesTable(g1);
end
tf = isequaln(edgeprop1, edgeprop2);
end
