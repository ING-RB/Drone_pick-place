%CompositeDataProcessor
% An implementation of the DataProcessor interface that wraps around a
% graph of DataProcessor instances. All DataProcessor instances must be
% non-communicating except for last or most downstream DataProcessor.
%
% Specifically, CompositeDataProcessor represents a graph such that:
%
%  1. Nodes (1 : NumInputs) represent the inputs of CompositeDataProcessor/process
%
%  2. Nodes (NumInputs + 1 : end) each represent one DataProcessor
%
%  3. Edges between nodes represent a dependency between the output of one
%  node and the corresponding DataProcessor that will consume it.
%
%  4. The output of CompositeDataProcessor is exactly the output of the
%  last node.

%   Copyright 2015-2019 The MathWorks, Inc.

classdef (Sealed) CompositeDataProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % Cell array of node processors for nodes that represent a
        % DataProcessor object.
        %
        % Note, cells 1 : NumInputs will be empty because the corresponding
        % nodes represent inputs.
        NodeProcessors;
        
        % Cell array containing for each node, the predecessor indices for
        % that node. We store this as it is slightly more efficient over
        % using an adjacency matrix.
        NodePredecessors;
        
        % Array of counts of successors of each node. This is used to
        % cleanup the output of each node immediately when it is no longer
        % needed.
        NodeSuccessorCounts;
        
        % The number of inputs expected by the CompositeDataProcessor.
        NumInputs;
    end
    
    properties (Access = private)
        % Cache of output of iIsNodeFinished. This is used to ignore
        % processors that are finished as well as those whose output will
        % no longer effect any of the final output.
        IsNodeFinished;
        
        % Cache of output of iIsNodeRequired. This is used both to
        % determine IsMoreInputRequired as well as which processors to
        % ignore.
        IsNodeRequired;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function out = process(obj, isLastOfInputVector, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            out = iProcess(...
                isLastOfInputVector, varargin, obj.IsNodeFinished, obj.IsNodeRequired, ...
                obj.NodeProcessors, obj.NodePredecessors, obj.NodeSuccessorCounts, obj.NumInputs);
            obj.updateState(isLastOfInputVector);
        end
        
        function prog = progress(obj, inputProgress)
            prog = iProgress(inputProgress, obj.NodeProcessors, obj.NodePredecessors);
        end
    end
    
    methods (Access = ?matlab.bigdata.internal.executor.CompositeDataProcessorBuilder)
        function obj = CompositeDataProcessor(nodeProcessors, adjacencyWithOrder, numInputs)
            %CompositeDataProcessor Private constructor for the builder.
            obj.NumOutputs = nodeProcessors{end}.NumOutputs;
            obj.NodeProcessors = nodeProcessors;
            obj.NodePredecessors = iBuildNodePredecessors(adjacencyWithOrder, numInputs);
            obj.NodeSuccessorCounts = sum(logical(adjacencyWithOrder), 2);
            obj.NumInputs = numInputs;
            obj.updateState(false(1, numInputs));
        end
    end
    
    methods (Access = private)
        function updateState(obj, isLastOfInputVector)
            %updateState Update the state of this object to reflect the
            %state of the underlying processors.
            obj.IsFinished = obj.NodeProcessors{end}.IsFinished;
            obj.IsNodeFinished = iIsNodeFinished(obj.NodeProcessors, obj.NodePredecessors, obj.NumInputs);
            obj.IsNodeRequired = iIsNodeRequired(obj.NodeProcessors, obj.NodePredecessors, obj.NumInputs);
            obj.IsMoreInputRequired = ~isLastOfInputVector & obj.IsNodeRequired(1:obj.NumInputs)';
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = iProcess(...
    isLastOfInputVector, inputs, isNodeFinished, isNodeRequired, ...
    nodeProcessors, nodePredecessors, nodeSuccessorCounts, numInputs)
%iProcess Perform one process step.
%
% This will iterate over all underlying processors in sequence. It uses an
% cell array of intermediate states as the means to connect the output of
% processors to where they need to be sent.

isLastOfInputVector = isLastOfInputVector(:);
inputs = inputs(:);

numNodes = numel(nodeProcessors);
assert(numel(isLastOfInputVector) == numInputs && numel(inputs) == numInputs, ...
    'Number of inputs different to expected number of inputs');

nodeOutputs = cell(numNodes, 1);

% Deal with inputs first.
if numInputs > 0
    nodeOutputs(1:numInputs) = inputs;
    isNodeFinished(1:numInputs) = isLastOfInputVector;
    isNodeRequired(1:numInputs) = isNodeRequired(1:numInputs) | ~cellfun(@isempty, inputs);
end

% Then all DataProcessors.
for nodeIdx = numInputs + 1 : numNodes
    processor = nodeProcessors{nodeIdx};
    predecessors = nodePredecessors{nodeIdx};
    
    % Skip the processor if it's already finished.
    if isNodeFinished(nodeIdx)
        nodeOutputs{nodeIdx} = cell(0, processor.NumOutputs);
        continue;
    end
    
    data = [{isNodeFinished(predecessors)'}; nodeOutputs(predecessors)];
    nodeSuccessorCounts(predecessors) = nodeSuccessorCounts(predecessors) - 1;
    nodeOutputs(nodeSuccessorCounts == 0) = {[]};
    
    if ~isNodeFinished(nodeIdx) && (isNodeRequired(nodeIdx) || any(isNodeRequired(predecessors)))
        data = process(processor, data{:});
        isNodeRequired(nodeIdx) = true;
    else
        data = cell(0, processor.NumOutputs);
    end
    
    nodeOutputs{nodeIdx} = data;
    isNodeFinished(nodeIdx) = processor.IsFinished;
end

output = nodeOutputs{end};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function prog = iProgress(inputProgress, nodeProcessors, nodePredecessors)
%iProgress Calculate the progress through the current partition.
nodeProgress = zeros(size(nodeProcessors));
nodeProgress(1:numel(inputProgress)) = inputProgress;
for nodeIdx = numel(inputProgress) + 1 : numel(nodeProcessors)
    nodeProgress(nodeIdx) = progress(nodeProcessors{nodeIdx}, nodeProgress(nodePredecessors{nodeIdx}));
end
prog = nodeProgress(end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function isNodeFinished = iIsNodeFinished(nodeProcessors, nodePredecessors, numInputs)
%iIsNodeFinished Determine which parts of the calculation will no longer be
%required to finish the final output.

numNodes = numel(nodeProcessors);

isNodeFinished = true(numNodes, 1);
isNodeFinished(end) = false;
% We only need to process DataProcessor nodes because input nodes are
% guaranteed not to have predecessors.
for nodeIdx = numNodes : -1 : numInputs + 1
    processor = nodeProcessors{nodeIdx};
    
    isNodeFinished(nodeIdx) = isNodeFinished(nodeIdx) || processor.IsFinished;
    if ~isNodeFinished(nodeIdx)
        predecessors = nodePredecessors{nodeIdx};
        isNodeFinished(predecessors) = false;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function isNodeRequired = iIsNodeRequired(nodeProcessors, nodePredecessors, numInputs)
%iIsNodeRequired Determine which parts of the calculation are required to
% allow the entire calculation move forward.

numNodes = numel(nodeProcessors);

isNodeRequired = false(numNodes, 1);
isNodeRequired(end) = true;
% We only need to process DataProcessor nodes because input nodes are
% guaranteed not to have predecessors.
for nodeIdx = numNodes : -1 : numInputs + 1
    processor = nodeProcessors{nodeIdx};
    
    isNodeRequired(nodeIdx) = isNodeRequired(nodeIdx) && ~processor.IsFinished;
    if isNodeRequired(nodeIdx)
        predecessors = nodePredecessors{nodeIdx};
        isNodeRequired(predecessors) = isNodeRequired(predecessors) | processor.IsMoreInputRequired(:);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function nodePredecessors = iBuildNodePredecessors(adjacencyWithOrder, numInputs)
%iBuildNodePredecessors Build the NodePredecessors property
numNodes = size(adjacencyWithOrder, 2);
nodePredecessors = cell(numNodes, 1);
% We only need to process DataProcessor nodes because input nodes are
% guaranteed not to have predecessors.
for nodeIdx = numInputs + 1 : numNodes
    d = adjacencyWithOrder(:, nodeIdx);
    idx = find(d);
    order = nonzeros(d);
    idx(order) = idx;
    nodePredecessors{nodeIdx} = idx;
end
end
