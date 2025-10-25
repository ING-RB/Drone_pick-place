function [G, EdgeProps, NodeProps] = constructFromTable(isDirected, ETable, varargin)
% CONSTRUCTFROMTABLE Construct graph/digraph from tables

% Copyright 2015-2020 The MathWorks, Inc.

if isDirected
    msgFlag = 'digraph';
else
    msgFlag = 'graph';
end
if nargin > 4
    error(message('MATLAB:maxrhs'));
end
varnames = ETable.Properties.VariableNames;
if varnames{1} ~= "EndNodes"
    error(message(['MATLAB:graphfun:' msgFlag ':InvalidTableFormat']));
end
EndNodes = ETable.EndNodes;
if ~ismatrix(EndNodes) || size(EndNodes,2) ~= 2 || ...
        ~(isnumeric(EndNodes) || iscellstr(EndNodes) || isstring(EndNodes))
    error(message(['MATLAB:graphfun:' msgFlag ':InvalidTableSize'])); 
end
% Peel off back argument and check for 'omitselfloops'
omitFlag = {};
if numel(varargin) > 0
    flag = varargin{end};
    if (ischar(flag) && isrow(flag)) || (isstring(flag) && isscalar(flag))
        omitLoops = startsWith("omitselfloops", flag, 'IgnoreCase', true) && strlength(flag) > 0;
        if ~omitLoops
            error(message(['MATLAB:graphfun:' msgFlag ':InvalidFlag']));
        end
        varargin(end) = [];
        omitFlag = {flag};
    elseif nargin == 4
        error(message(['MATLAB:graphfun:' msgFlag ':InvalidFlag']));
    end
end
NTable = {};
if numel(varargin) > 0
    NTable = varargin(1);
    if ~istable(NTable{1})
        error(message(['MATLAB:graphfun:' msgFlag ':SecondNotTable']));
    end
end
[G, EdgeProps, NodeProps] = matlab.internal.graph.constructFromEdgeList(isDirected, ...
        EndNodes(:,1), EndNodes(:,2), ETable(:,2:end), NTable{:}, omitFlag{:});

