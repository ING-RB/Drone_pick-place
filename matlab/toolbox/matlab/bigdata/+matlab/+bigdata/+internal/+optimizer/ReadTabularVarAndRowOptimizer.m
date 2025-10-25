%ReadTabularVarAndRowOptimizer Optimizer that attempts to apply read-time
%filtering of tabular rows with matlab.io.RowFilter and/or reduce the
%number of selected variables to read from datastore when using subsref for
%tall tables and timetables.
%
% See also: matlab.bigdata.internal.optimizer.ReadTabularVarSubsrefOptimizer

%   Copyright 2022-2024 The MathWorks, Inc.

classdef ReadTabularVarAndRowOptimizer < matlab.bigdata.internal.Optimizer

    properties (Constant)
        % List of datastore classes that have SelectedVariableNames and
        % RowFilter as properties to be optimized with
        % ReadTabularVarAndRowOptimizer.
        DatastoreForOptimization = ["matlab.io.datastore.ParquetDatastore", ...
            "matlab.io.datastore.DatabaseDatastore"];
    end

    methods (Static)
        function [allowed, restoreFcn] = enableOrDisableOptimization(dsClass, onOff)
            % Enable/Disable ReadTabularVarAndRowOptimizer optimization for
            % datastore class.
            import matlab.bigdata.internal.optimizer.ReadTabularVarAndRowOptimizer;

            persistent ALLOWED
            if isempty(ALLOWED)
                ALLOWED = ReadTabularVarAndRowOptimizer.DatastoreForOptimization;
            end
            allowed = ALLOWED;
            restoreFcn = [];
            if nargin == 2
                if onOff == "on"
                    % Add new datastore class
                    ALLOWED = union(ALLOWED, dsClass);
                    assert(nargout == 2, 'When adding a class, must capture restore function for cleanup.');
                    restoreFcn = @() ReadTabularVarAndRowOptimizer.enableOrDisableOptimization(dsClass, "off");
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
            % Check valid successors for tabular row and variable subsref:
            % SubsrefTabularVar and LogicalRowSubsref.
            for ii = 1:numReadClosures
                oldReadOp = readClosures{ii}.Operation;
                [canOptimize, smallSubs, rowFilter] = ...
                    iCanOptimize(graphObj, oldReadOp, readNodeNames{ii});

                if ~canOptimize
                    continue;
                elseif isempty(rowFilter)
                    % Only tabular variable optimization. Create new read
                    % operation with updated SelectedVariableNames
                    % property.
                    assert(~isempty(smallSubs), ...
                        'Assertion failed: expected non-empty smallSubs for optimization.');
                    undoGuard = iOptimizeReadOperation(undoGuard, readClosures{ii}, ...
                        oldReadOp, smallSubs);
                elseif isempty(smallSubs)
                    % Only tabular row optimization. Create new read
                    % operation with updated RowFilter property.
                    assert(~isempty(rowFilter), ...
                        'Assertion failed: expected non-empty rowFilterCondition for optimization');
                    undoGuard = iOptimizeReadOperation(undoGuard, readClosures{ii}, ...
                        oldReadOp, [], rowFilter);
                else
                    % Tabular variable and row optimization. Create new
                    % read operation with updated SelectedVariableNames and
                    % RowFilter properties.
                    undoGuard = iOptimizeReadOperation(undoGuard, readClosures{ii}, ...
                        oldReadOp, smallSubs, rowFilter);
                end

            end

            if ~nargout
                disarm(undoGuard);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function isValidReadClosure = iFindValidReadClosuresForThisOptimizer(graphObj)
% Identify closure nodes with ReadOperation with valid datastores for this
% optimizer.
isClosure = graphObj.Nodes.IsClosure;
numNodes = numnodes(graphObj);
isValidReadClosure = false(numNodes, 1);
isValidReadClosure(isClosure) = cellfun(@iIsValidReadClosure, graphObj.Nodes.NodeObj(isClosure));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsValidReadClosure(closure)
import matlab.bigdata.internal.optimizer.ReadTabularVarAndRowOptimizer;
% Check if a given closure is a ReadOperation
op = closure.Operation;
tf = isa(op, 'matlab.bigdata.internal.lazyeval.ReadOperation');
if tf
    % Check that it has a valid datastore for this optimizer, i.e. it has
    % both RowFilter and SelectedVariableNames properties.
    ds = op.Datastore;
    if isa(ds, "matlab.io.datastore.internal.FrameworkDatastore")
        ds = ds.Datastore;
    end
    clz = class(ds);
    tf = tf & ismember(clz, ReadTabularVarAndRowOptimizer.enableOrDisableOptimization());
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [canOptimize, smallSubs, rowFilter] = iCanOptimize(graphObj, readOperation, readNodeName)
% Check that the successors of the ReadOperation satisfy all the conditions
% to create a single condition of row-filtering or a combination of
% multiple conditions: Read - SubsrefTabularVar - AdaptorAssertion (if
% enabled) - SmallTallComparisonOperation - (LogicalElementwise) -
% LogicalRowSubsref.

% Identify which operations are successors of each ReadOperation.
% Row-indexing syntaxes that we're looking for in the graph are shown below
% with the corresponding successors of Read:
% t(t.Var1 > 1, :) -> SubsrefTabularVar and LogicalRowSubsref
% t.Var2(t.Var1 > 1) -> 2 SubsrefTabularVar
% Thus we want to keep track of the following three types of successors
% from read: SubsrefTabularVar, LogicalRowSubsref, and anything else.
[nSubsrefVarFromRead, nSubsrefRowFromRead, nNonSubsrefFromRead, ...
    subsrefVarFromReadNodeIdx, subsrefRowFromReadNodeIdx] = iFindSuccessorsOfRead(graphObj, readNodeName);

% Early exit if there's a non-subsref operation as a direct successor of
% read. That successor requires the entire tall (time)table and we can't
% reduce the data to read.
if nNonSubsrefFromRead > 0
    canOptimize = false;
    smallSubs = [];
    rowFilter = [];
    return;
end

% Look for branches where SubsrefTabularVar is a successor of read, this
% will point us to single-condition syntaxes such as t.Var1 > 1.
% 1. Capture all the valid branches and their corresponding successor
% indices. For each valid branch, create the corresponding constrained
% RowFilter object that represents the condition found.
% 2. Capture if there are any branches that do not contain a valid
% single-condition according to the current restrictions of
% matlab.io.RowFilter, this will help us to early exit the tabular row
% optimization and move forward to tabular variable optimization if
% applicable.
% 3. If there's not a valid single-condition that starts from this
% SubsrefTabularVar, capture if the successor is a LogicalRowSubsref
% operation. If that's the case we have a valid row-indexing expression
% like: t.Var2(t.Var1 > 1), where this SubsrefTabularVar node is the one
% extracting t.Var2 in the example.
% 4. Capture the variables selected in each SubsrefTabularVar as well to
% gather all the required information for variable optimization if
% applicable afterwards.

hasValidSingleConditions = false(nSubsrefVarFromRead, 1);
hasTabularRowSuccessor = false(nSubsrefVarFromRead, 1);

% foundConditions is a cell array where each element is a
% maltab.io.RowFilter with a constrained variable as indicated by the
% single condition found. conditionsSuccessorsIdx is a column vector where
% each element corresponds to the successor index of each condition in
% foundConditions.
foundConditions = {};
conditionsSuccessorsIdx = [];

% selectedVarsFromTabularVar is a cell array where each element is a cell
% array with the selected variable names in SubsrefTabularVar.
selectedVarsFromTabularVar = cell(nSubsrefVarFromRead, 1);

% Create initial unconstrained matlab.io.RowFilter from the datastore of
% the Read Operation that we're analyzing.
ds = readOperation.Datastore;
if isa(ds, "matlab.io.datastore.internal.FrameworkDatastore")
    ds = ds.Datastore;
end
% Directly access the RowFilter property of the datastore, the convenience
% function rowfilter is not yet enabled for
% matlab.io.datastore.DatabaseDatastore.
rf = ds.RowFilter;

for ii = 1:size(subsrefVarFromReadNodeIdx, 1)
    thisNodeIdx = subsrefVarFromReadNodeIdx(ii);
    thisNode = graphObj.Nodes(thisNodeIdx, :);

    % Search for valid single conditions from this SubsrefTabularVar node.
    [hasValidSingleConditions(ii), newConditions, newConditionsSuccessorsIdx] = ...
        iFindValidSingleConditionSequence(graphObj, thisNodeIdx, rf);

    % If this node doesn't have a valid condition, we still need to figure
    % out if this SubsrefTabularVar node has a LogicalRowSubsref node as
    % successor. If that's the case we have a valid row-indexing expression
    % like: t.Var2(t.Var1 > 1), where this SubsrefTabularVar node is the
    % one extracting t.Var2 in the example.
    tabularVarSuccessorsIdx = iFindValidSuccessorsOfCondition(graphObj, thisNodeIdx);
    if ~isempty(tabularVarSuccessorsIdx)
        tabularVarSuccessorOps = graphObj.Nodes.OpType(tabularVarSuccessorsIdx);
        validRowSubsrefSuccessors = tabularVarSuccessorOps == "LogicalRowSubsrefOperation";
        if all(validRowSubsrefSuccessors)
            hasTabularRowSuccessor(ii) = true;
        end
    end

    % Append newConditions and their successors.
    foundConditions = [foundConditions; newConditions]; %#ok<AGROW> 
    conditionsSuccessorsIdx = [conditionsSuccessorsIdx; newConditionsSuccessorsIdx]; %#ok<AGROW> 

    % At this point we may or may not have a valid condition for tabular
    % row optimization but we may still be able to perform tabular variable
    % optimization. So, keep track of the required selected variables for
    % this subsrefTabularVar node. Subs is guaranteed to be a cell array
    % with the selected variable names.
    selectedVarsFromTabularVar{ii} = thisNode.NodeObj{1}.Operation.Subs;
end

% At this point, we have found out if the SubsrefTabularVar successors from
% read contain a valid condition or they are valid for row-indexing
% optimization because their successor is a LogicalRowSubsref operation
% (e.g. t.Var1(t.Var1 > 1)).
validSubsrefVarForRowOptim = hasValidSingleConditions | hasTabularRowSuccessor;

% To continue with row-indexing optimiation, at least we need a valid
% single condition to move forward with row-indexing optimization.
if ~all(validSubsrefVarForRowOptim) || sum(hasValidSingleConditions) == 0
    if nSubsrefRowFromRead > 0
        % If none of these conditions are met and there's at least one
        % LogicalRowSubsref that requires all the variables in the
        % table/timetable, we can't optimize row or variable indexing here.
        canOptimize = false;
        smallSubs = [];
        rowFilter = [];
    else
        % If none of these conditions are met and all the successors from
        % read are SubsrefTabularVar, we can't optimize row-indexing but we
        % might be able to optimize variable-indexing.
        rowFilter = [];
        smallSubs = iExtractSmallSubs(selectedVarsFromTabularVar);
        if isempty(smallSubs)
            % No variables have actually been selected, edge case of
            % indexing with [] as the second subs.
            canOptimize = false;
        else
            canOptimize = true;
        end
    end
    return;
end

% Before analyzing whether we can enable row indexing optimization, resolve
% if we can perform variable optimization. It only depends on the
% successors of read, they must all be subsrefTabularVar nodes, and we
% can't have any LogicalRowSubsref node as successor of read.
if nSubsrefRowFromRead == 0
    % All successors from Read are subsrefTabularVar, create the subset of
    % selected variables.
    smallSubs = iExtractSmallSubs(selectedVarsFromTabularVar);
else
    % There's at least one LogicalRowSubsref operation that takes all the
    % variables of the tall table. Keep the subset of selected variables
    % unset.
    smallSubs = [];
end

% Analyze successors of each single-condition to merge the
% single-conditions found. Valid successors are LogicalElementwiseOperation
% and LogicalRowSubsrefOperation. Here we need the information in:
% foundConditions & conditionsSuccessorsIdx.
resolvedSuccessors = false(size(conditionsSuccessorsIdx));
finalConditions = {};
k = 1;
while ~all(resolvedSuccessors)
    if resolvedSuccessors(k)
        % Skip already resolved successors.
        k = k + 1;
        if k > length(resolvedSuccessors)
            % Restart, there's a pending successor to analyze.
            k = 1;
        end
        continue;
    end
    thisSuccessorIdx = conditionsSuccessorsIdx(k);
    successorNode = graphObj.Nodes(thisSuccessorIdx, :);
    opType = successorNode.OpType;
    % For this successor node, who are the predecessors? We can find the
    % following cases:
    % 1. A LogicalElementwiseOperation (AND, OR) with two known
    % predecessors with two valid conditions.
    % 2. A LogicalElementwiseOperation (NOT) with a single predecessor that
    % is known.
    % 3. A LogicalElementwiseOperation (AND, OR) with a known
    % predecessor and a compound condition yet to be discovered.
    % 4. A LogicalRowSubsrefOperation with a condition as a parent and the
    % other parent can be a Read node or a SubsrefTabularVarFromRead node.
    foundPredecessors = foundConditions(conditionsSuccessorsIdx == thisSuccessorIdx);
    if opType == "LogicalElementwiseOperation"
        logicalOperator = successorNode.NodeObj{1}.Operation.LogicalOperator;
        if numel(foundPredecessors) == 2 ...
                || (isscalar(foundPredecessors) && isequal(logicalOperator, @not))
            % Cases 1 & 2: Two conditions are merged with AND/OR operators
            % or a condition is negated with NOT.
            newCondition = logicalOperator(foundPredecessors{:});
            % Mark this successor index as RESOLVED.
            resolvedSuccessors(conditionsSuccessorsIdx == thisSuccessorIdx) = true;
            % Append the new condition (if valid, that is, this node has
            % LogicalElementwise or LogicalRowSubsref as successors).
            successorsIdx = iFindValidSuccessorsOfCondition(graphObj, thisSuccessorIdx);
            if ~isempty(successorsIdx)
                % Make sure that we analyze all the possible successors of
                % a combined condition.
                foundConditions = [foundConditions; repmat({newCondition}, numel(successorsIdx), 1)]; %#ok<AGROW>
                conditionsSuccessorsIdx = [conditionsSuccessorsIdx; successorsIdx]; %#ok<AGROW>
                resolvedSuccessors = [resolvedSuccessors; false(numel(successorsIdx), 1)]; %#ok<AGROW>
            else
                % The successor of this LogicalElementwiseOperation is not
                % a valid successor for row-indexing. Stop here and mark
                % whether we can optimize variable-indexing.
                canOptimize = ~isempty(smallSubs);
                rowFilter = [];
                return;
            end
        else
            % Case 3: This LogicalElementwiseOperation (AND, OR) has a
            % known predecessor and a compound condition yet to be
            % discovered. Continue resolving other unresolved successors.
            k = k + 1;
        end
    else
        % Case 4: SubsrefTabularVarRowOperation
        assert(opType == "LogicalRowSubsrefOperation", ...
            'Assertion failed: Expected LogicalRowSubsrefOperation from a single condition.');
        isSuccessorOfRead = ismember(thisSuccessorIdx, subsrefRowFromReadNodeIdx);
        predecessorsIdx = iFindPredecessorsOfLogicalRowSubsref(graphObj, thisSuccessorIdx);
        isSuccessorOfTabularVar = any(ismember(predecessorsIdx, subsrefVarFromReadNodeIdx));
        if isSuccessorOfRead || isSuccessorOfTabularVar
            % We have a valid condition that reaches a row-indexing node
            % (LogicalRowSubsref) where we're extracting the entire table
            % or a subset of variables of the table: t(condition, :) or
            % t(condition, variables). We've reached the end for this
            % condition, mark it as RESOLVED and continue analyzing (if any
            % condition remains unresolved).
            resolvedSuccessors(conditionsSuccessorsIdx == thisSuccessorIdx) = true;
            % Now that we've reached a LogicalRowSubsref node, this is a
            % final condition to add for row-indexing. Since a single
            % condition can be used for row-indexing of multiple variables,
            % it will be found as many times as the variables indexed by
            % it. Make sure we don't duplicate already found conditions.
            isAlreadyFinalCondition = any(cellfun(@(x) isequal(x, foundConditions{k}), finalConditions));
            if ~isAlreadyFinalCondition
                finalConditions = [finalConditions; foundConditions(k)]; %#ok<AGROW>
            end
        else
            % This row-indexing operation doesn't have a valid parent
            % besides the condition found.  Stop here and mark whether we
            % can optimize variable-indexing.
            canOptimize = ~isempty(smallSubs);
            rowFilter = [];
            return;
        end
    end
end

% At this point, foundConditions contains all the conditions that extract
% different subsets of data from the table. If there are multiple of them,
% for example: tA = t(t.Var1 > 1, :); tB = t(t.Var1 < 1, :);
% We combine them with OR to extract all the required rows by all the
% conditions found.
rowFilter = finalConditions{1};
for k = 2:numel(finalConditions)
    rowFilter = rowFilter | finalConditions{k};
end
canOptimize = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nSubsrefVarFromRead, nSubsrefRowFromRead, nNonSubsrefFromRead, ...
    subsrefVarFromReadClosureIdx, subsrefRowFromReadClosureIdx] = iFindSuccessorsOfRead(graphObj, readNodeName)
% Find Read closure successors by navigating through the graph.
readClosureIdx = findnode(graphObj, readNodeName);
readSuccessorsIdx = iFindSuccessorsOfClosureIdx(graphObj, readClosureIdx);

nSubsrefVarFromRead = 0;
nSubsrefRowFromRead = 0;
nNonSubsrefFromRead = 0;
subsrefVarFromReadClosureIdx = [];
subsrefRowFromReadClosureIdx = [];
for ii = 1:numel(readSuccessorsIdx)
    % Check the underlying operation
    thisSuccessorIdx = readSuccessorsIdx(ii);
    nodeInfo = graphObj.Nodes(thisSuccessorIdx, :);
    opType = nodeInfo.OpType;
    if opType == "LogicalRowSubsrefOperation"
        nSubsrefRowFromRead = nSubsrefRowFromRead + 1;
        subsrefRowFromReadClosureIdx = [subsrefRowFromReadClosureIdx; thisSuccessorIdx]; %#ok<AGROW> 
    elseif opType == "SubsrefTabularVarOperation"
        nSubsrefVarFromRead = nSubsrefVarFromRead + 1;
        subsrefVarFromReadClosureIdx = [subsrefVarFromReadClosureIdx; thisSuccessorIdx]; %#ok<AGROW> 
    else
        nNonSubsrefFromRead = nNonSubsrefFromRead + 1;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hasValidSingleConditions, conditionsFromTabularVar, conditionSuccessorsIdx] = ...
    iFindValidSingleConditionSequence(graphObj, subsrefVarFromReadClosureIdx, initialRowFilter)
% Check that the successors of the given SubsrefTabularVar closure follow
% the sequence of operations that defines a single condition for
% row-indexing: SubsrefTabularVar -> AdaptorAssertion (if enabled) +
% SmallTallComparisonOperation and their successor is LogicalElementwise or
% LogicalRowSubsref. If we find a valid sequence, we create a
% matlab.io.RowFilter with the information of the selected variable (Subs
% in SubsrefTabularVar), the BinaryOperator, the small operand and the
% argument order in SmallTallComparisonOperation. We also keep track of the
% valid sequence successors indices for further processing of successors.

% Find SubsrefTabularVar successors 
subsrefSuccessorsIdx = iFindSuccessorsOfClosureIdx(graphObj, subsrefVarFromReadClosureIdx);

if numel(subsrefSuccessorsIdx) == 0
    % Early exit if SubsrefTabularVar doesn't have any successors. This is
    % the case when AdaptorAssertion is disabled and we're only extracting
    % variables from tabular data.
    hasValidSingleConditions = false;
    conditionsFromTabularVar = {};
    conditionSuccessorsIdx = [];
    return;
end

nInvalidSuccessors = 0;
nValidLogicalRowSuccessors = 0;
conditionsFromTabularVar = {};
conditionSuccessorsIdx = [];
for ii = 1:numel(subsrefSuccessorsIdx)
    thisNodeIdx = subsrefSuccessorsIdx(ii);
    thisNode = graphObj.Nodes(thisNodeIdx, :);
    % First check if the underlying operation is AdaptorAssertion.
    % If enabled, AdaptorAssertion is always triggered before any kind of
    % elementwise operations, including SmallTallComparisonOperation, which
    % is the one we're looking for.
    if thisNode.OpType == "AdaptorAssertionOperation"
        % Find its successor, it only has a single successor that is some
        % kind of elementwise operation.
        thisNodeIdx = iFindSuccessorsOfClosureIdx(graphObj, thisNodeIdx);
        thisNode = graphObj.Nodes(thisNodeIdx, :);
    end
    % Now look for SmallTallComparison operations, they will point us to a
    % valid condition for row-indexing optimization.
    opType = thisNode.OpType;
    if opType == "SmallTallComparisonOperation"
        % This is a valid condition, we only trigger
        % SmallTallComparisonOperation when there's a small operand for the
        % binary comparison. Now check its successors. If one of them is a
        % LogicalRowSubsrefOperation or a LogicalElementwiseOperation, this
        % is a valid condition to track with the index of its successor.
        successorsIdx = iFindValidSuccessorsOfCondition(graphObj, thisNodeIdx);
        if ~isempty(successorsIdx)
            % Extract information from the related operations and create
            % the RowFilter for the condition found.
            subsrefVarFromReadNode = graphObj.Nodes(subsrefVarFromReadClosureIdx, :);
            subsrefVarOperation = subsrefVarFromReadNode.NodeObj{1}.Operation;
            binaryOperation = thisNode.NodeObj{1}.Operation;
            newCondition = iCreateSingleConditionRowFilter(initialRowFilter, subsrefVarOperation, binaryOperation);
            % A single condition may have multiple valid successors, e.g.
            % t.Var1(tIndex) & t.Var2(tIndex) where tIndex is the condition
            % found and equal to t.Var1 == 1. Make sure that there's always
            % a condition assigned to a condition successor index.
            conditionsFromTabularVar = [conditionsFromTabularVar; repmat({newCondition}, numel(successorsIdx), 1)]; %#ok<AGROW>
            conditionSuccessorsIdx = [conditionSuccessorsIdx; successorsIdx]; %#ok<AGROW>
        else
            nInvalidSuccessors = nInvalidSuccessors + 1;
        end
    elseif opType == "LogicalRowSubsrefOperation"
        % It's valid to have LogicalRowSubsrefOperation as a successor of
        % SubsrefTabularVar: that's the case for t.Var1(t.Var1 > 1). It
        % can't be marked as invalidSuccessor, we treat it as a special
        % case.
        nValidLogicalRowSuccessors = nValidLogicalRowSuccessors + 1;
        continue;
    else
        nInvalidSuccessors = nInvalidSuccessors + 1;
    end
end

if nInvalidSuccessors > 0
    % Early exit if one of the branches from SubsrefTabularVar doesn't
    % contain a valid condition or a LogicalRowSubsref.
    hasValidSingleConditions = false;
    conditionsFromTabularVar = {};
    conditionSuccessorsIdx = [];
    return;
end

if nValidLogicalRowSuccessors > 0 && isempty(conditionsFromTabularVar)
    % LogicalRowSubsref is a valid successor for '.' indexing operation. We
    % need to treat it as special but it can't be marked as invalid. Early
    % exit if only '.' indexing is performed without valid conditions for
    % row-indexing optimization. We might still be able to perform
    % variable-indexing optimization.
    hasValidSingleConditions = false;
    conditionsFromTabularVar = {};
    conditionSuccessorsIdx = [];
    return;
end

hasValidSingleConditions = true;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function successorsIdx = iFindSuccessorsOfClosureIdx(graphObj, closureIdx)
% Helper that returns the node indices in graphObj for the successors of
% the given closure index. For this optimizer, it's a valid to assume that
% all the closures that we need to analyze (Read, SubsrefTabularVar,
% AdaptorAssertion, SmallTallComparison, LogicalElementwise) return a
% single future. They all return a single output. We navigate through the
% graph downwards: Closure - Future - Closure.
futuresIdx = successors(graphObj, closureIdx);
if numel(futuresIdx) >= 2
    successorsIdx = [];
    return;
end
successorsIdx = successors(graphObj, futuresIdx);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function successorIdx = iFindValidSuccessorsOfCondition(graphObj, closureIdx)
% Helper that returns the index in graphObj for the valid successor of a
% condition, this is, LogicalRowSubsrefOperation (row-indexing) or
% AdaptorAssertionOperation (if enabled) + LogicalElementwiseOperation
% (AND/OR/NOT). LogicalElementwiseOperation is only triggered with these 3
% logical operators.
allSuccessorsIdx = iFindSuccessorsOfClosureIdx(graphObj, closureIdx);
successorOps = graphObj.Nodes.OpType(allSuccessorsIdx);
validRowSubsrefSuccessors = successorOps == "LogicalRowSubsrefOperation";
if matlab.bigdata.internal.util.enableAdaptorAssertion()
    % Assertions are enabled and AdaptorAssertionOperation is injected
    % before LogicalElementwiseOperation.
    validLogicalSuccessors = successorOps == "AdaptorAssertionOperation";
    if any(validLogicalSuccessors)
        % Return the successor of each AdaptorAssertion if it's a
        % LogicalElementwiseOperation.
        adaptorAssertionClosureIdx = allSuccessorsIdx(validLogicalSuccessors);
        adaptorAssertionSuccessorsIdx = [];
        for k = 1:size(adaptorAssertionClosureIdx, 1)
            newSuccessorIdx = iFindSuccessorsOfClosureIdx(graphObj, adaptorAssertionClosureIdx(k));
            adaptorAssertionSuccessorsIdx = [adaptorAssertionSuccessorsIdx; newSuccessorIdx]; %#ok<AGROW>
        end
        adaptorAssertionSuccessorOpTypes = graphObj.Nodes.OpType(adaptorAssertionSuccessorsIdx);
        validAdaptorSuccessors = adaptorAssertionSuccessorOpTypes == "LogicalElementwiseOperation";
        logicalSuccessorsIdx = adaptorAssertionSuccessorsIdx(validAdaptorSuccessors);
    else
        logicalSuccessorsIdx = [];
    end
else
    % AdaptorAssertion is disabled, directly look for
    % LogicalElementwiseOperation.
    validLogicalSuccessors = successorOps == "LogicalElementwiseOperation";
    logicalSuccessorsIdx = allSuccessorsIdx(validLogicalSuccessors);
end
RowSubsrefSuccessorsIdx = allSuccessorsIdx(validRowSubsrefSuccessors);
successorIdx = [logicalSuccessorsIdx; RowSubsrefSuccessorsIdx];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rowFilter = iCreateSingleConditionRowFilter(rf, subsrefVarOperation, smallTallCompOperation)
% Creates a matlab.io.RowFilter object from a given RowFilter object and
% the information available in the related operations: SubsrefTabularVar
% and SmallTallComparison.

subs = subsrefVarOperation.Subs;
binaryOperator = smallTallCompOperation.BinaryOperator;
smallOperand = smallTallCompOperation.SmallOperand;
isTallFirstArg = smallTallCompOperation.IsTallFirstArg;

if isTallFirstArg
    rowFilter = binaryOperator(rf.(subs), smallOperand);
else
    rowFilter = binaryOperator(smallOperand, rf.(subs));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function smallSubs = iExtractSmallSubs(subs)
% Get the unique set of table variable subscripts from all the
% SubsrefTabularVarOperations.
smallSubs = cell(1,0);
for ii = 1:numel(subs)
    smallSubs = union(smallSubs, subs{ii}{:}, 'stable');
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function predecessorsIdx = iFindPredecessorsOfLogicalRowSubsref(graphObj, closureIdx)
% Helper that returns the node indices in graphObj for the predecessors of
% the given LogicalRowSubsref node. In this case, this node will have two
% inputs, thus we'll find two predecessors. We navigate through the graph
% upwards: Closure - Future - Closure.
futuresIdx = predecessors(graphObj, closureIdx);
predecessorsIdx = [];
for k = 1:numel(futuresIdx)
    newPredecessorIdx = predecessors(graphObj, futuresIdx(k));
    predecessorsIdx = [predecessorsIdx newPredecessorIdx]; %#ok<AGROW> 
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function undoGuard = iOptimizeReadOperation(undoGuard, readClosure, oldReadOp, smallSubs, rowFilter)
% Perform optimization of the ReadOperation.

% Create new ReadOperation with the subset of SelectedVariableNames in
% smallSubs and/or the RowFilter object in rowFilterCondition.
if nargin < 5
    newReadOp = iCreateNewReadOperation(oldReadOp, smallSubs);
else
    newReadOp = iCreateNewReadOperation(oldReadOp, smallSubs, rowFilter);
end
newReadClosure = matlab.bigdata.internal.lazyeval.Closure(readClosure.InputFutures, ...
    newReadOp);

% Swap futures
originalFutures = readClosure.OutputFutures;
optimizedFutures = newReadClosure.OutputFutures;
undoGuard.swapAndAppend(originalFutures, optimizedFutures);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newReadOp = iCreateNewReadOperation(oldReadOp, smallSubs, rowFilter)
% Create new ReadOperation as the original ReadOperation with the subset
% of SelectedVariableNames and/or the new RowFilter.
datastore = oldReadOp.Datastore;
numOutputs = oldReadOp.NumOutputs;

if nargin < 3
    % Only optimize SelectedVariableNames
    newReadOp = matlab.bigdata.internal.lazyeval.ReadOperation(datastore, numOutputs, ...
        smallSubs);
    return;
end

% To optimize RowFilter, the new RowFilter can only have constrains on the
% already selected variables in the datastore. To provide optimization, we
% need to update the selected variable names to include all the constrained
% variables in the new RowFilter. After reading, subsrefTabularVar and
% LogicalRowSubsref operations will filter out the variables that are not
% needed for those particular operations.
if isempty(smallSubs)
    smallSubs = datastore.SelectedVariableNames;
end

% Force 1xN cellstr from constrainedVariableNames() on the rowFilter so
% that we can set the new set of variable names in the datastore,
% constrainedVariableNames returns a string vector.
constrainedVars = cellstr(constrainedVariableNames(rowFilter));
smallSubs = union(smallSubs, constrainedVars, 'stable');
newReadOp = matlab.bigdata.internal.lazyeval.ReadOperation(datastore, numOutputs, ...
    smallSubs, rowFilter);
end
