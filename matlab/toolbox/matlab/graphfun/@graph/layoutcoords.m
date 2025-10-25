function [nodeCoords, edgeCoords] = layoutcoords(G, method, varargin)
%LAYOUTCOORDS Coordinates of nodes and edges in a layout of a graph
%
%   [NODECOORDS,EDGECOORDS] = LAYOUTCOORDS(G) calculates the coordinates 
%   of the nodes and edges of G by using an automatic choice of layout 
%   method based on the structure of the graph.
%
%   [NODECOORDS,EDGECOORDS] = LAYOUTCOORDS(G,METHOD) optionally specifies 
%   the layout method.
%   METHOD can be:
%       'auto'      (Default) Automatic choice of layout method based on
%                   the structure of the graph.
%       'circle'    Circular layout.
%       'force'     Force-directed layout. Uses attractive and repulsive 
%                   forces on nodes.
%       'layered'   Layered layout. Places nodes in a set of layers.
%       'subspace'  Subspace embedding layout. Uses projection onto an 
%                   embedded subspace.
%       'force3'    3-D force-directed layout.
%       'subspace3' 3-D subspace embedding layout.
%
%   [NODECOORDS,EDGECOORDS] = LAYOUTCOORDS(G,METHOD,NAME,VALUE) uses 
%   additional options specified by one or more Name-Value pair arguments. 
%   The optional argument names can be:
%       'circle'    Supports 'Center'.
%       'force'     Supports 'Iterations', 'UseGravity', 'WeightEffect',
%                   'XStart', 'YStart'.
%       'force3'    Supports 'Iterations', 'UseGravity', 'WeightEffect', 
%                   'XStart', 'YStart', 'ZStart'.
%       'layered'   Supports 'AssignLayers', 'Direction', 'Sinks',
%                   'Sources'.
%       'subspace'  Supports 'Dimension'.
%       'subspace3' Supports 'Dimension'.
%   See the reference page for a description of each Name-Value pair.
%
%   Example:
%       % Find the node and edge coordinates of a plotted graph using an
%       % automatic choice of layout method.
%       s = [1 1 1 2 2 3 3 4 5 5 6 7];
%       t = [2 4 5 3 6 4 7 8 6 8 7 8];
%       G = graph(s,t);
%       [nodeCoords, edgeCoords] = layoutcoords(G)
%
%	Example:
%       % Find the node and edge coordinates of a plotted graph using the
%       % "circle" layout with "Center" set to node 1.
%       s = [1 1 1 2 2 3 3 4 5 5 6 7];
%       t = [2 4 5 3 6 4 7 8 6 8 7 8];
%       G = graph(s,t);
%       [nodeCoords, edgeCoords] = layoutcoords(G,"circle","Center",1)
%
%   See also GRAPH/PLOT

%   Copyright 2024 The MathWorks, Inc.

arguments
    G {mustBeA(G,'graph')}
    method = "auto"
end
arguments (Repeating)
    varargin
end

NodeNames = getNodeNames(G);
EdgeWeights = getEdgeWeights(G);
args = [{method}, varargin];

[XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, Layout] = ...
    matlab.internal.graph.layout(G.Underlying, NodeNames, EdgeWeights, args{:});

if ismember(Layout,["circle","force","layered","subspace"])
    nodeCoords = [reshape(XData,[],1), reshape(YData,[],1)];
    EdgeCoords(:,3) = [];
elseif ismember(Layout,["force3","subspace3"])
    nodeCoords = [reshape(XData,[],1), reshape(YData,[],1), reshape(ZData,[],1)];
end
rowDist = groupcounts(EdgeCoordsIndex);
edgeCoords = mat2cell(EdgeCoords,rowDist);
end
