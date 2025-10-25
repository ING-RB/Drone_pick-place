%ReadTabularVarSubsrefOptimizer Optimizer that attempts to reduce the number
% of selected variables to read from datastore when using subsref for tall
% table/timetable variables.
%
% This optimization will take place under the following conditions:
%
% 1. There is a ReadOperation from a TabularTextDatastore or a
% SpreadsheetDatastore.
% 2. There is at least one SubsrefTabularVarOperations that read from
% datastore.
% 3. ReadOperation doesn't have successors of another kind of operations.
%
% When all the conditions are met, it replaces the original ReadOperation
% with a new one that will access the unique set of variable names given by
% the SubsrefTabularVarOperations of condition 2.

% Copyright 2018-2024 The MathWorks, Inc.

classdef ReadTabularVarSubsrefOptimizer < matlab.bigdata.internal.Optimizer
    
    properties (Constant)
        % List of datastore classes that have SelectedVariableNames as
        % property and can be optimized with
        % ReadTabularVarSubsrefOptimizer. We exclude ParquetDatastore
        % because it has a RowFilter property and it can benefit from
        % tabular row optimization in ReadTabularVarAndRowOptimizer.
        DatastoreForOptimization = {...
            'matlab.io.datastore.TabularTextDatastore', ...
            'matlab.io.datastore.SpreadsheetDatastore'};
    end
    
    methods (Static)
        function [allowed, restoreFcn] = enableOrDisableOptimization(dsClass, onOff)
            % Enable/Disable ReadTabularVarSubsref optimization for datastore
            % class.
            import matlab.bigdata.internal.optimizer.ReadTabularVarSubsrefOptimizer;
            
            persistent ALLOWED
            if isempty(ALLOWED)
                ALLOWED = ReadTabularVarSubsrefOptimizer.DatastoreForOptimization;
            end
            allowed = ALLOWED;
            restoreFcn = [];
            if nargin == 2
                if onOff == "on"
                    % Add new datastore class
                    ALLOWED = union(ALLOWED, dsClass);
                    assert(nargout == 2, 'When adding a class, must capture restore function for cleanup.');
                    restoreFcn = @() ReadTabularVarSubsrefOptimizer.enableOrDisableOptimization(dsClass, "off");
                else
                    % Remove datastore class
                    ALLOWED = setdiff(ALLOWED, dsClass);
                end
            end
        end
    end
    
    methods
        function undoGuard = optimize(~, varargin)
            undoGuard = matlab.bigdata.internal.optimizer.UndoGuard;
            
            closureGraph = matlab.bigdata.internal.optimizer.ClosureGraph(varargin{:});
            graphObj = closureGraph.Graph;
            
            % Identify valid Read closures for this optimizer in the graph
            isValidReadClosure = iFindValidReadClosuresForThisOptimizer(graphObj);
            % Early exit if there are no ReadOperations in the graph
            numReadClosures = sum(isValidReadClosure);
            if numReadClosures == 0
                return;
            end
            
            readClosures = graphObj.Nodes.NodeObj(isValidReadClosure);
            readNodeNames = graphObj.Nodes.Name(isValidReadClosure);
            for ii = 1:numReadClosures
                % Check if the conditions above are met to perform
                % optimization
                [canOptimize, smallSubs] = iCanOptimize(graphObj, readNodeNames{ii});
                if canOptimize
                    oldReadOp = readClosures{ii}.Operation;
                    undoGuard = iOptimizeReadOperation(undoGuard, readClosures{ii}, oldReadOp, smallSubs);
                end
            end
            
            if ~nargout
                disarm(undoGuard);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [isReadClosure] = iFindValidReadClosuresForThisOptimizer(graphObj)
% Identify closure nodes with ReadOperation with valid datastores for this
% optimizer.
isClosure = graphObj.Nodes.IsClosure;
numNodes = numnodes(graphObj);
isReadClosure = false(numNodes, 1);
isReadClosure(isClosure) = cellfun(@iIsValidReadClosure, graphObj.Nodes.NodeObj(isClosure));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsValidReadClosure(closure)
import matlab.bigdata.internal.optimizer.ReadTabularVarSubsrefOptimizer;
% Check if a given closure is a ReadOperation
op = closure.Operation;
tf = isa(op, 'matlab.bigdata.internal.lazyeval.ReadOperation');
if tf
    % Check that it has a valid datastore for this optimizer, i.e. it has
    % a datastore with SelectedVariableNames property.
    clz = class(op.Datastore);
    if isequal(clz, 'matlab.io.datastore.internal.FrameworkDatastore')
        clz = class(op.Datastore.Datastore);
    end
    tf = tf & ismember(clz, ReadTabularVarSubsrefOptimizer.enableOrDisableOptimization());
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [canOptimize, smallSubs] = iCanOptimize(graphObj, readNodeName)
% Check that all the conditions to optimize are satisfied

% Find successors of Read
[nSubsrefFromRead, nNonSubsrefFromRead, subsrefFromReadClosures] = iFindSuccessorsOfRead(...
    graphObj, readNodeName);

% Check if there is at least one SubsrefTabularVarOperation but no other
% Operations as successors of Read
if (nSubsrefFromRead == 0) || (nNonSubsrefFromRead ~= 0)
    canOptimize = false;
    smallSubs = [];
    return;
end

% Extract SubsrefTabularVarOperations that are successors of Read
subsrefOps = cellfun(@(closure) subsref(closure, substruct('.', 'Operation')), ...
    subsrefFromReadClosures);

% Extract unique set of smallSubs
smallSubs = iExtractSmallSubsFromSubsrefOps(subsrefOps);

% Optimize if it is a subsref with Table/Timetable variable
% names. At this point, smallSubs is a cellstr with table
% variable names created by subsref methods in
% TabularAdaptor.
if ~iscellstr(smallSubs) || any(strcmpi(smallSubs,':')) %#ok<ISCLSTR>
    canOptimize = false;
    smallSubs = [];
    return;
end

canOptimize = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nSubsrefFromRead, nNonSubsrefFromRead, subsrefFromReadClosures] = iFindSuccessorsOfRead(graphObj, readClosure)
% Find Read closure successors by navigating through the graph:
% Closure - Future - Closure
% Read closures return a single future, futuresFromRead is guaranteed
% scalar here.
readClosureIdx = findnode(graphObj, readClosure);
futuresFromReadIdx = successors(graphObj, readClosureIdx);
readSuccessorsIdx = successors(graphObj, futuresFromReadIdx);

nSubsrefFromRead = 0;
nNonSubsrefFromRead = 0;
subsrefFromReadClosures = {};
for ii = 1:numel(readSuccessorsIdx)
    % Check the underlying operation
    nodeInfo = graphObj.Nodes(readSuccessorsIdx(ii), :);
    opType = nodeInfo.OpType;
    if opType == 'SubsrefTabularVarOperation' %#ok<BDSCA>
        nSubsrefFromRead = nSubsrefFromRead + 1;
        newClosure = nodeInfo.NodeObj;
        subsrefFromReadClosures = [subsrefFromReadClosures newClosure]; %#ok<AGROW>
    else
        nNonSubsrefFromRead = nNonSubsrefFromRead + 1;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function smallSubs = iExtractSmallSubsFromSubsrefOps(subsrefOps)
% Get the unique set of table variable subscripts from all the
% SubsrefTabularVarOperations
smallSubs = {};
for ii = 1:numel(subsrefOps)
    smallSubs = union(smallSubs, subsrefOps(ii).Subs{:});
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function undoGuard = iOptimizeReadOperation(undoGuard, readClosure, oldReadOp, smallSubs)
% Perform optimization

% Create new ReadOperation with the subset of SelectedVariableNames in
% smallSubs
newReadOp = iCreateNewReadOperation(oldReadOp, smallSubs);
newReadClosure = matlab.bigdata.internal.lazyeval.Closure(readClosure.InputFutures, ...
    newReadOp);

% Swap futures
originalFutures = readClosure.OutputFutures;
optimizedFutures = newReadClosure.OutputFutures;
undoGuard.swapAndAppend(originalFutures, optimizedFutures);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newReadOp = iCreateNewReadOperation(oldReadOp, smallSubs)
% Create new ReadOperation as the original ReadOperation with the subset
% of SelectedVariableNames
datastore = oldReadOp.Datastore;
numOutputs = oldReadOp.NumOutputs;
newReadOp = matlab.bigdata.internal.lazyeval.ReadOperation(datastore, numOutputs, ...
    smallSubs);
end
