function [paths, edgepaths] = allpaths(G, s, t, varargin)
% AllPATHS Compute all paths between two nodes
%   PATHS = ALLPATHS(G, S, T) computes all the paths in graph G that start
%   at node S and end at node T. PATHS is a cell array in which PATHS{i} is
%   a vector of numeric node IDs (if S and T are node indices), a string
%   vector (if S and T are string node names), or a cell array of character
%   vectors (if S and T are character vector node names). If node T is
%   unreachable from node S, then PATHS is empty. The paths are in
%   lexicographical order.
%
%   [PATHS, EDGEPATHS] = ALLPATHS(G, S, T) also returns a cell array
%   EDGEPATHS in which EDGEPATHS{i} contains the edges on the path PATHS{i}
%   from node S to node T.
%
%   [...] = ALLPATHS(G, S, T, Name, Value) specifies one or more additional
%   options using name-value pair arguments. The available options are:
%
%         'MaxNumPaths' - A scalar that specifies the maximum number
%                         of paths in the output.
%       'MaxPathLength' - A scalar that specifies the maximum path
%                         length of paths in the output.
%       'MinPathLength' - A scalar that specifies the minimum path
%                         length of paths in the output.
%
%   See also SHORTESTPATH, SHORTESTPATHTREE, DISTANCES, ALLCYCLES

%   Copyright 2020 The MathWorks, Inc.

src = validateNodeID(G, s);
if numel(src) ~= 1
    error(message('MATLAB:graphfun:allpaths:NonScalarSource'));
end
targ = validateNodeID(G, t);
if numel(targ) ~= 1
    error(message('MATLAB:graphfun:allpaths:NonScalarTarg'));
end

[maxNumPaths, maxPathLength, minPathLength] =  parseInputs(varargin{:});

if maxPathLength < minPathLength
    paths = cell(0, 1);
    edgepaths = cell(0, 1);
    return
end

% Determine which nodes are reachable on a path from s to t. This is only
% possible for nodes which are part of at least one biconnected component
% which lies on any path from s to t
[~, d, edgepath] = shortestpath(G, src, targ, 'Method', 'unweighted');
if d == inf
    paths = cell(0, 1);
    edgepaths = cell(0, 1);
    return
end
edgebins = biconncomp(G);

% Self-loops have edgebins entry 0, replace this by a valid indexing value
edgebins(edgebins == 0) = max(edgebins)+1; 
isCompOnPath = false(1, max(edgebins));
isCompOnPath(edgebins(edgepath)) = true;
isEdgePotentiallyOnPath = isCompOnPath(edgebins);

% A node is unreachable if it connects to no edge that is potentially on
% the path
[ss, tt] = findedge(G);
A = sparse(ss, tt, isEdgePotentiallyOnPath, numnodes(G), numnodes(G)); 
A = A | A';
unreachable = full(~any(A, 1));

% Compute paths and edgepaths
try
    if nargout < 2
        paths = allSimplePaths(G.Underlying, src, targ, maxNumPaths,...
            maxPathLength, minPathLength, unreachable);
    else
        [paths, edgepaths] = allSimplePaths(G.Underlying, src, targ, maxNumPaths,...
            maxPathLength, minPathLength, unreachable);
    end
catch e
    if e.identifier == "MATLAB:nomem"
        error(message('MATLAB:graphfun:allpaths:nomem'));
    else
        rethrow(e);
    end
end

% If G has node names
if ~isnumeric(s) && ~isnumeric(t)
    names = getNodeNames(G).';
    for i = 1:size(paths, 1)
        ps = names(paths{i});
        if isstring(s) || isstring(t)
            ps = string(ps);
        end
        paths{i} = ps;
    end
end
end

function [maxNumPaths, maxPathLength, minPathLength] =  parseInputs(varargin)
names = {'MaxNumPaths', 'MaxPathLength', 'MinPathLength'};
maxNumPaths = Inf;
maxPathLength = Inf;
minPathLength = 0;
for i = 1:2:numel(varargin)
    opt = validatestring(varargin{i}, names);
    if i+1 > numel(varargin)
        error(message('MATLAB:graphfun:allpaths:KeyWithoutValue', opt));
    end
    switch opt
        case 'MaxNumPaths'
            maxNumPaths = varargin{i+1};
            validateattributes(maxNumPaths, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer'}, '', 'MaxNumPaths')
        case 'MaxPathLength'
            maxPathLength = varargin{i+1};
            validateattributes(maxPathLength, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer'}, '', 'MaxPathLength')
        case 'MinPathLength'
            minPathLength = varargin{i+1};
            validateattributes(minPathLength, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer'}, '', 'MinPathLength')
    end
end
end
