function [cycles, edgecycles] = allcycles(G, varargin)
% ALLCYCLES Compute all cycles in graph
%   CYCLES = ALLCYCLES(G) computes all the cycles in graph G. CYCLES is a
%   cell array in which CYCLES{i} is a vector of numeric node IDs (if G
%   does not have node names) or a cell array of character vectors (if G
%   has node names). Each cycle in CYCLES begins with the smallest node
%   index. If G is acyclic, then CYCLES is empty. The cycles are in
%   lexicographical order.
%
%   [CYCLES, EDGECYCLES] = ALLCYCLES(G) also returns a cell array
%   EDGECYCLES in which EDGECYCLES{i} contains the edges on the cycle
%   CYCLES{i} of G.
%
%   [...] = ALLCYCLES(G, Name, Value) specifies one or more additional
%   options using name-value pair arguments. The available options are:
%
%         'MaxNumCycles' - A scalar that specifies the maximum number
%                          of cycles in the output.
%       'MaxCycleLength' - A scalar that specifies the maximum cycle
%                          length of cycles in the output.
%       'MinCycleLength' - A scalar that specifies the minimum cycle
%                          length of cycles in the output.
%
%   See also ISDAG, HASCYCLES, CYCLEBASIS, ALLPATHS

%   Copyright 2020-2021 The MathWorks, Inc.
%
%   Reference:
%   Johnson, Donald B. "Finding all the elementary circuits of a directed
%   graph." SIAM Journal on Computing 4.1 (1975): 77-84.


[maxNumCycles, maxCycleLength, minCycleLength] = parseInputs(varargin{:});

if maxCycleLength < minCycleLength
    cycles = cell(0, 1);
    edgecycles = cell(0, 1);
    return
end

try
    if nargout < 2
        cycles = allSimpleCycles(G.Underlying, maxNumCycles, maxCycleLength,...
            minCycleLength);
    else
        [cycles, edgecycles] = allSimpleCycles(G.Underlying, maxNumCycles,...
            maxCycleLength, minCycleLength);
    end
catch e
    if e.identifier == "MATLAB:nomem"
        error(message('MATLAB:graphfun:allcycles:nomem'));
    else
        rethrow(e);
    end
end

[names, hasNodeNames] = getNodeNames(G);
names = names.';
if hasNodeNames
    for i = 1:size(cycles, 1)
        cycles{i} = names(cycles{i});
    end
end
end

function [maxNumCycles, maxCycleLength, minCycleLength] = parseInputs(varargin)
names = {'MaxNumCycles', 'MaxCycleLength', 'MinCycleLength'};
maxNumCycles = Inf;
maxCycleLength = Inf;
minCycleLength = 1;
for i = 1:2:numel(varargin)
    opt = validatestring(varargin{i}, names);
    if i+1 > numel(varargin)
        error(message('MATLAB:graphfun:allcycles:KeyWithoutValue', opt));
    end
    switch opt
        case 'MaxNumCycles'
            maxNumCycles = varargin{i+1};
            validateattributes(maxNumCycles, {'numeric'}, {'scalar', 'real', 'nonnegative', 'integer'}, '', 'MaxNumCycles')
        case 'MaxCycleLength'
            maxCycleLength = varargin{i+1};
            validateattributes(maxCycleLength, {'numeric'}, {'scalar', 'real', 'positive', 'integer'}, '', 'MaxCycleLength')
        case 'MinCycleLength'
            minCycleLength = varargin{i+1};
            validateattributes(minCycleLength, {'numeric'}, {'scalar', 'real', 'positive', 'integer'}, '', 'MinCycleLength')
    end
end
end
