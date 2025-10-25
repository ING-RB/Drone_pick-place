function varargout = executionGraph(varargin)
%executionGraph visualize lazy evaluation graph for tall array
%   matlab.bigdata.internal.util.executionGraph(X) plots an execution
%   graph for tall array X.
%
%   [G,P] = matlab.bigdata.internal.util.executionGraph(X) returns in G a graph
%   object and in P the resulting plot object.
%
%   matlab.bigdata.internal.util.executionGraph(...,'Simplify',TF) toggle
%   basic execution graph simplification. Defaults to true.
%
%   matlab.bigdata.internal.util.executionGraph(...,'Optimize',TF) toggle
%   execution graph optimization.  Defaults to false.
%
%   matlab.bigdata.internal.util.executionGraph(...,'VariableNames',NAMES)
%   names used for input tall arrays.
%
%   matlab.bigdata.internal.util.executionGraph(...,'Direction',DIR) the
%   graph layout direction.  Defaults to "right".
%
%   matlab.bigdata.internal.util.executionGraph(...,'MarkerWeight',W) a
%   weighting factor used to rescale the node markers.
%
%   matlab.bigdata.internal.util.executionGraph(...,'HighlightOperation',Q)
%   will highlight any nodes that match the supplied query.


% Copyright 2016-2024 The MathWorks, Inc.

% Argument checking
nargoutchk(0, 2);
[tallArgs, opts] = iParseInputs(varargin{:});

partitionedArrays = cellfun(@hGetValueImpl, tallArgs, ...
                            'UniformOutput', false);
if opts.Optimize
    optimizer = matlab.bigdata.internal.Optimizer.default();
    optimizer.optimize(partitionedArrays{:});
end

% Get and (optionally) simplify the graph of closures.
closureGraph = matlab.bigdata.internal.optimizer.ClosureGraph(partitionedArrays{:});
graph        = closureGraph.Graph;
if opts.Simplify
    % This stage removes futures from the graph.
    graph = iSimplifyGraph(graph);
end

% Grab all input argument names
if isempty(opts.VariableNames)
    inputNames = cell(numel(tallArgs), 1);
    for idx = 1:numel(tallArgs)
        inputNames{idx} = inputname(idx);
    end
else
    inputNames = opts.VariableNames;
end

% Update node names and labels to show extra information
graph = iUpdateNodeNamesAndLabels(graph, tallArgs, inputNames, opts.Direction);

% Plot the resulting graph
p = plot(graph, ...
         'Layout', 'layered', ...
         'Direction', opts.Direction, ...
         'MarkerSize', opts.MarkerWeight .* graph.Nodes.MarkerSize, ...
         'LineWidth', graph.Edges.Weight, ...
         'Marker', graph.Nodes.Marker, ...
         'NodeLabel', [], ...
         'NodeColor', graph.Nodes.Color, ...
         'ArrowSize', 4);
ax = p.Parent;

highlight(p, ...
    'Edges', find(graph.Edges.Weight > 1), ...
    'EdgeColor', [0.4940    0.1840    0.5560]);

if ~isempty(opts.HighlightOperation)
    % Highlight matching operations in bright green.
    doHighlight = contains(...
        string(graph.Nodes.OpType), ...
        opts.HighlightOperation, ...
        "IgnoreCase", true);
    
    green = [0 1 0];
    highlight(p, doHighlight, "NodeColor", green);
    graph.Nodes{doHighlight, "Color"} = green;
end

iAddLegend(ax, graph.Nodes);


set(ax, "XTick", [], "YTick", []); % Turn off the tick marks as they don't mean anything for graphs
if nargout > 0
    varargout = {graph, p};
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tallArgs, opts] = iParseInputs(varargin)
% Strip off P-V pairs
firstP = find(cellfun(@(x) ischar(x) || isStringScalar(x), varargin), 1, 'first');
if isempty(firstP)
    tallArgs = varargin;
    pvPairs  = {};
else
    tallArgs = varargin(1:(firstP-1));
    pvPairs  = varargin(firstP:end);
end

for ii = 1:numel(tallArgs)
    if isa(tallArgs{ii}, 'matlab.bigdata.internal.PartitionedArray')
        tallArgs{ii} = tall(tallArgs{ii});
    end
end
assert(all(cellfun(@istall, tallArgs)), ...
       'All data inputs to %s must be tall arrays.', upper(mfilename));
numTallArgs = numel(tallArgs);

% Interpret P-V pairs.
p = inputParser;
scalarLogicalValidator = @(x) validateattributes(x, {'logical'}, {'scalar'});
addParameter(p, 'Simplify', true, scalarLogicalValidator);
addParameter(p, 'Optimize', false, scalarLogicalValidator);

varNamesValidator = @(x) validateattributes(x, {'cell', 'string'}, {'row', 'numel', numTallArgs});
addParameter(p, 'VariableNames', [], varNamesValidator);

validDirections = ["down", "up", "left", "right"];
directionValidator = @(x) any(startsWith(validDirections, x, "IgnoreCase", true));
addParameter(p, 'Direction', 'right', directionValidator);

weightValidator = @(x) validateattributes(x, "numeric", ["scalar", "positive"]);
addParameter(p, 'MarkerWeight', 1, weightValidator);

opValidator = @matlab.internal.datatypes.isText;
addParameter(p, 'HighlightOperation', [], opValidator);

p.parse(pvPairs{:});
opts = p.Results;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simplify graph by attempting to skip over the futures that are
% interspersed between closures.
function g = iSimplifyGraph(g)
% Walk the graph in topologically-sorted order so we can start at the top.
g = reordernodes(g, toposort(g));
isClosure = g.Nodes.IsClosure;
% Default is to keep nodes, until we work out that we've skipped over them.
keepNodes = true(numnodes(g), 1);
dists = distances(g);
for idx = 1:numnodes(g)
    if isClosure(idx)
        % Downstream closures are at distance 2 (1 for future).
        distsThisNode = dists(idx, :);
        downstreamClosures = find(distsThisNode == 2);
        g = addedge(g, idx, downstreamClosures);
        % Trim nodes we skipped over
        if ~isempty(downstreamClosures)
            dropThisTime = any(distsThisNode == 1);
            keepNodes(dropThisTime) = false;
        end
    end
end
g = rmnode(g, find(~keepNodes));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update node names and labels for all remaining elements in the graph.
function graph = iUpdateNodeNamesAndLabels(graph, inputTallArrays, inputNames, direction)

% Use partitioning to determine edge weights
numNodes = numnodes(graph);
[weights, partitioning] = iCalcEdgeWeightsAndPartitioning(graph);
graph.Edges.Weight = weights;

% Compute a marker size. 1 for future (not many remain); 5 for closures;
% 7 for sources/sinks.
markerSize = ones(numNodes, 1);
markerSize(graph.Nodes.IsClosure) = 5;
sources = indegree(graph) == 0;
sinks   = outdegree(graph) == 0;
markerSize(sources | sinks) = 7;
constants = sources & ~graph.Nodes.IsClosure;

% Emphasize the nodes where the partitioning changes by turning the marker
% size all the way up to 11.
changeNodes = diff(partitioning, 1, 2) ~= 0;
markerSize(changeNodes) = 11;

% Update 'OpType' to include Constants / Outputs / Others.
graph.Nodes.OpType(constants) = categorical({'Constant'});
graph.Nodes.OpType(~graph.Nodes.IsClosure & sinks) = categorical({'Output'});
graph.Nodes.OpType(ismissing(graph.Nodes.OpType)) = categorical({'Other'});
opType = regexprep(cellstr(graph.Nodes.OpType), 'Operation$', '');
graph.Nodes.OpType = categorical(opType);

% Join in color and marker
graph.Nodes = join(graph.Nodes, iOpTypeMappingTable(direction));
graph.Nodes.MarkerSize = markerSize;

% Set up default label to be index in topological sort.
graph.Nodes.Label = cellstr(num2str((1:numNodes)'));

% Compute labels and names for closures, sources, sinks
graph = iUpdateClosureNamesAndLabels(graph);
graph = iUpdateSinkNamesAndLabels(graph, inputTallArrays, inputNames);
graph = iUpdateConstantNamesAndLabels(graph);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name and labels for closure nodes.
function graph = iUpdateClosureNamesAndLabels(graph)
isClosure    = graph.Nodes.IsClosure;
nodeObjs     = graph.Nodes{isClosure, 'NodeObj'};
opTypes      = graph.Nodes{isClosure, 'OpType'};
closureNames = cell(1, numel(nodeObjs));

% We keep closure labels only for nodes that are not single-input-single-output.
keepLabel    = isClosure & (indegree(graph) > 1 | outdegree(graph) > 1);
graph.Nodes.Label(~keepLabel) = {''};

for idx = 1:numel(nodeObjs)
    nodeObj = nodeObjs{idx};
    opType  = opTypes(idx);
    % Starting point for the name is based on the underlying Id, but we'll override
    % this.
    n       = nodeObj.Id;
    switch opType
        case 'Read'
            n = iReadDescription(nodeObj.Operation);
        case {'Slicewise', 'Elementwise', 'AdaptorAssertion', ...
                'SmallTallComparison', 'LogicalElementwise'}
            n = iFunctionDescription(nodeObj.Operation.FunctionHandle);
        case {'SubsrefTabularVar'}
            n = iSubsrefTabularVarDescription(nodeObj.Operation);
        case {'Filter', 'Chunkwise', 'Partitionwise', 'LogicalRowSubsref'}
            n = iFunctionDescription(nodeObj.Operation.FunctionHandle);
        case {'Aggregate', 'AggregateByKey'}
            n = sprintf('Aggregate: %s\nReduce: %s\n', ...
                iFunctionDescription(nodeObj.Operation.PerChunkFunctionHandle), ...
                iFunctionDescription(nodeObj.Operation.ReduceFunctionHandle));
        case {'FusedAggregateByKey'}
            cell2strfcn = @(c) strjoin(cellfun(@iFunctionDescription, c, ...
                'UniformOutput', false), '\n');
            n = sprintf('Aggregates: %s\nReduces: %s\n', ...
                cell2strfcn(nodeObj.Operation.PerChunkFunctionHandles), ...
                cell2strfcn(nodeObj.Operation.ReduceFunctionHandles));
        case {'Cache'}
        case {'NonPartitioned'}
            n = iFunctionDescription(nodeObj.Operation.FunctionHandle);
    end
    closureNames{idx} = sprintf('%s (%d):\n%s\n', opType, idx, n);
end
graph.Nodes.Name(isClosure) = closureNames;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Names and labels for sink nodes. Try and match up to the original inputname to
% the tall array.
function graph = iUpdateSinkNamesAndLabels(graph, inputArgsTall, inputNamesCell)
isSink    = outdegree(graph) == 0;
sinkObjs  = graph.Nodes{isSink, 'NodeObj'};
labelCell = repmat({''}, numel(sinkObjs), 1);
nameCell  = strcat('Output: ', cellstr(num2str((1:numel(sinkObjs))')));

graph.Nodes.Name(isSink) = nameCell;

% Look through the input names and see if we can match things up.
if numel(sinkObjs) == numel(inputArgsTall)
    inputPA  = cellfun(@hGetValueImpl, inputArgsTall, 'UniformOutput', false);
    inputFut = cellfun(@(x) x.ValueFuture, inputPA, 'UniformOutput', false);
    inputFut = [inputFut{:}];
    for sIdx = 1:numel(sinkObjs)
        match = inputFut == sinkObjs{sIdx};
        if sum(match) == 1
            if ~isempty(inputNamesCell{match})
                labelCell(sIdx) = inputNamesCell(match);
            else
                labelCell{sIdx} = 'ans';
            end
        end
    end
    graph.Nodes.Label(isSink) = labelCell;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Names and labels for constants
function graph = iUpdateConstantNamesAndLabels(graph)
constantIdxs = find(indegree(graph) == 0 & ~graph.Nodes.IsClosure);
constantObjs = graph.Nodes{constantIdxs, 'NodeObj'};

[names, labels] = cellfun(@iConstantInfo, constantObjs, num2cell(constantIdxs), ...
    'UniformOutput', false);

graph.Nodes.Name(constantIdxs) = names;
graph.Nodes.Label(constantIdxs) = labels;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function l = iAddLegend(ax, nodeTable)
[~, tf] = unique(nodeTable.OpType);
mapping = nodeTable(tf, ["Color", "Marker", "OpType"]);
lines = cell(height(mapping), 1);

for idx = 1:height(mapping)
    if mapping{idx, "OpType"} == "Other"
        continue
    end
    marker = mapping{idx, "Marker"};
    color  = mapping{idx, "Color"};
    % Make a secret line object solely for the purposes of the legend.
    lines{idx} = line(ax, NaN, NaN, 'Marker', marker{1}, ...
        'LineStyle', 'none', ...
        'MarkerFaceColor', color, ...
        'MarkerEdgeColor', color, ...
        'DisplayName', string(mapping{idx, "OpType"}));
end
l = legend([lines{:}], "Location", "northwestoutside");
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Definition of color and marker for each operation type.
function t = iOpTypeMappingTable(direction)
persistent MAPPING_TABLE
if isempty(MAPPING_TABLE)
    % Define a handful of colors from the default color order
    blue   = [ 0        0.4470    0.7410];
    orange = [0.8500    0.3250    0.0980];
    gold   = [0.9290    0.6940    0.1250];
    violet = [0.4940    0.1840    0.5560];
    green  = [0.4660    0.6740    0.1880];
    sky    = [0.3010    0.7450    0.9330];
    
    data = { ... sources/sinks
             'Read',                     blue, 'triangle';
             'Constant',                 blue, 'p';
             'Output',                   blue, '*';
             ... plain operations
             'Slicewise',                blue, 'o';
             'FusedSlicewise',           blue, 'o';
             'Elementwise',              blue, 'o';
             'PadWithEmptyPartitions',   blue, 'd';
             'SelectNonEmptyPartition',  blue, 'o';
             'Filter',                   blue, 'o';
             'ChunkResize',              blue, 'o';
             'Chunkwise',                blue, 'o';
             'FixedChunkwise',           blue, 'o';
             'Encellification',          blue, 'o';
             'Partitionwise',            blue, 'o';
             'GeneralizedPartitionwise', blue, 'o';
             'Passthrough',              blue, 'o';
             'Cache',                    blue, 'o';
             'NonPartitioned',           blue, 'o';
             'Ternary',                  blue, 'o';
             'Gather',                   blue, 'o';
             'Other',                    blue, '.';
             ... special operations for read optimization
             'AdaptorAssertion',         sky,  'o';
             'LogicalElementwise',       sky,  'o';
             'LogicalRowSubsref',        sky,  'o';
             'SmallTallComparison',      sky,  'o';
             'SubsrefTabularVar',        sky,  'o';
             ... communicating operations
             'Aggregate',                orange, 'd';
             'FusedAggregate',           gold,   'triangle';
             'AggregateByKey',           violet, 's';
             'FusedAggregateByKey',      green,  'h';
             'Repartition',              sky,    'd'};
         
    MAPPING_TABLE = cell2table(data, ...
                               'VariableNames', {'OpType', 'Color', 'Marker'});
    MAPPING_TABLE.OpType = categorical(MAPPING_TABLE.OpType);
end
t = MAPPING_TABLE;

% Match up triangle marker direction with the graph layout direction
tmap = struct("down", 'v', "left", '<', "right", '>', "up", '^');
t.Marker = replace(t.Marker, "triangle", tmap.(direction));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Describes a read operation.
function txt = iReadDescription(operationObj)
try
    datastore = operationObj.Datastore;
    
    if isa(datastore, "matlab.io.datastore.internal.FrameworkDatastore")
        datastore = datastore.Datastore;
    end
    
    if isprop(datastore, 'Files')
        files = strrep(datastore.Files, matlabroot, '<matlab>');
        txt = sprintf('Read from: %s\n', strjoin(files, '\n'));
    else
        txt = sprintf('Read from in-memory data.\n');
    end
    
    if isprop(datastore, 'SelectedVariableNames')
        if isempty(operationObj.SelectedVariableNames)
            numVariables = numel(datastore.SelectedVariableNames);
        else
            numVariables = numel(operationObj.SelectedVariableNames);
        end
        
        variables = sprintf('Number of variables to read: %d\n', numVariables);
        txt = [txt, variables];
    end
    if isprop(datastore, 'RowFilter')
        if isempty(operationObj.RowFilter)
            txt = [txt, sprintf('No constrained variables\n')];
        else
            constrainedVars = constrainedVariableNames(operationObj.RowFilter);
            txt = [txt, sprintf('Constrained variables: %s\n', strjoin(constrainedVars, ", "))];
        end
    end
catch E
    txt = sprintf('Error occurred: %s', E.message);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Describes a function - shows the stack.
function txt = iFunctionDescription(functionObj)
try
    fcnHandle = matlab.bigdata.internal.util.unwrapFunctionHandle(functionObj.Handle);
    txt = sprintf('%s\n', func2str(fcnHandle));
    stackLines = arrayfun(@iFrameDescription, functionObj.ErrorStack, ...
                          'UniformOutput', false);
    txt = [txt, strjoin(stackLines, '\n')];
catch E
    txt = sprintf('Error occurred: %s', E.message);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Describes a SubsrefTabularVar function - shows the stack.
function txt = iSubsrefTabularVarDescription(operationObj)
try
    fcnHandle = matlab.bigdata.internal.util.unwrapFunctionHandle(operationObj.FunctionHandle);
    txt = sprintf('%s\n', func2str(fcnHandle));
    stackLines = arrayfun(@iFrameDescription, operationObj.Stack, ...
                          'UniformOutput', false);
    txt = [txt, strjoin(stackLines, '\n')];

    if ~isempty(operationObj.Subs)
        selectedVars = unique(string(operationObj.Subs{:}));
        variables = sprintf('\nSelected variables: %s', strjoin(selectedVars, ", "));
        txt = [txt, variables];
    end
catch E
    txt = sprintf('Error occurred: %s', E.message);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Describe a single stack frame.
function txt = iFrameDescription(frame)
if isempty(frame.file)
    txt = sprintf('%s:%d', frame.name, frame.line);
else
    % Got file & frame
    framefile = strrep(frame.file, matlabroot, '<matlab>');
    [fpath, fname] = fileparts(framefile);
    if isequal(fname, frame.name)
        txt = sprintf('%s:%d', framefile, frame.line);
    else
        txt = sprintf('%s/%s:%d', fpath, frame.name, frame.line);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the name and label for a constant source.
function [txt, label] = iConstantInfo(nodeObj, nodeIdx)

assert(isa(nodeObj, 'matlab.bigdata.internal.lazyeval.ClosureFuture'));
label = sprintf('Constant:%s', nodeIdx);
if nodeObj.IsDone
    val = nodeObj.Value;
    if isa(val, 'matlab.bigdata.internal.BroadcastArray')
        val = val.Value;
    end
    if isscalar(val) && (isnumeric(val) || islogical(val))
        shortVal = ['[', num2str(val), ']'];
        longVal  = ['value: ', shortVal];
    else
        shortVal = sprintf('%s [%s]', class(val), ...
                           matlab.bigdata.internal.util.formatBigSize(size(val)));
        longVal  = sprintf('%s\nvalue:\n%s', shortVal, ...
                           iTruncatedDisplay(val));
    end
else
    % How does one get here?
    shortVal = '';
    longVal  = '';
end
txt   = sprintf('%s\n%s', label, longVal);
label = shortVal;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Come up with a simple display for a constant value.
function txt = iTruncatedDisplay(val)
truncated = false;
if ~ismatrix(val)
    val = val(:,:,1);
    truncated = true;
end

limit = 8;
% val can also be a ColonDescriptor or an array
s = size(val); 
m = s(1);
n = s(2);

if any([m, n] > limit)
    truncated = true;
    if m == 1
        val = val(1:min(n,limit));                   %#ok<NASGU> used in EVALC
    else
        val = val(1:min(m, limit), 1:min(n, limit)); %#ok<NASGU> used in EVALC
    end
end
txt = evalc('disp(val)');
if truncated
    txt = sprintf('truncated:\n%s', txt);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate edge weights to emphasize communicating nodes.
function [weights, partitioning] = iCalcEdgeWeightsAndPartitioning(graph)
% Default to edge weight of 1 for non-partitioned node output and use edge
% weight = 5 for any nodes that have partitioned outputs.  This should help
% emphasize where partitioning is changing.

[in, out] = matlab.bigdata.internal.optimizer.determinePartitioning(graph);
partitioning = [in out];
weights = ones(numedges(graph), 1);
fatIds = find(out);

for ii = 1:numel(fatIds)
    fatEdges = outedges(graph, fatIds(ii));
    weights(fatEdges) = 2;
end
end
