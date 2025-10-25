function [out, isRowVectors, isARowVector] = setfunCommon(a, b, adaptorA, adaptorB, numOutputs, fcnName, flags)
% SETFUNCOMMON Common implementation for set functions with small/tall or
% tall/tall inputs.
%
% SETFUNCOMMON returns a table OUT with three variables as follows:
%       - C: Unique data elements from both inputs.
%       - indA: Corresponding indices for input A. If an element does not
%         exist in input A, the corresponding index will be set to 0.
%       - indB: Corresponding indices for input B. If an element does not
%         exist in input B, the corresponding index will be set to 0.
% Except for the case of union with a single output, where table OUT only
% contains the variable C.
%
% The result for each set function can be computed from table OUT.

%   Copyright 2018-2022 The MathWorks, Inc.

aIsTall = istall(a);
bIsTall = istall(b);

% Part 1. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Both inputs need to be column vectors, unless they are tables,
% timetables, or the 'rows' flag is specified. This means that any matrices
% are columnized.

% Need to check if both inputs are already column vectors. Scalar inputs
% are considered to be row vectors, since they give row vector outputs.
isColumnVectors = all(adaptorA.SmallSizes == 1) && all(adaptorB.SmallSizes == 1) ...
    && adaptorA.isKnownNotRow() && adaptorB.isKnownNotRow();
isRowsMode = ismember("rows", flags);
isTabular = adaptorA.Class == "table" || adaptorA.Class == "timetable";
isRowsOrTabular =  isTabular || isRowsMode;

isColumnizationNeeded = ~isColumnVectors && ~isRowsOrTabular;

% The first output of union does not require any index computation and can
% benefit from a better performance
isUnion = strcmpi(fcnName, 'union');
requiresIndexComputation = ~isUnion || numOutputs > 1;
% Setdiff has a different rule for row vectors. For all set functions, the
% output is a row vector if both inputs are row vectors. For setdiff, the
% output is a row vector if A is a row vector. We need to keep track if it
% is setdiff in order to sort and keep the result in a single partition.
isSetdiff = strcmpi(fcnName, 'setdiff');

% Columnize any matrices if necessary. Get indices for inputs A and B.
isRowVectors = false;
isARowVector = false;
if isColumnizationNeeded
    [a, b, indA, indB, isRowVectors, isARowVector] = iColumnizeInputsAandBwithIndices(a, b, adaptorA, adaptorB, aIsTall, bIsTall, numOutputs);
elseif requiresIndexComputation
    if numOutputs > 1
        indA = iGetSliceIndices(a, aIsTall);
        indB = iGetSliceIndices(b, bIsTall);
    else
        % Create a column vector for each input A and B that specifies the
        % origin of each element. This is required by all set methods
        % except from union.
        indA = iCreateOriginVectorForInput(a, aIsTall, 1);
        indB = iCreateOriginVectorForInput(b, bIsTall, 2);
    end
end

% Create origin vector for inputs A and B.
fromA = iCreateOriginVectorForInput(a, aIsTall, 1);
fromB = iCreateOriginVectorForInput(b, bIsTall, 2);

% Part 2. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Use tall/vertcat to merge A and B to create column vector C, get the
% indices of A and B in indC, and the origin vectors fromA and fromB in
% fromID.
c = [a; b];

if requiresIndexComputation
    indC = [indA; indB];
    fromID = [fromA; fromB];
end

% Place C, indC and fromID in tableC. fromId in tableC identifies if a row
% belongs to the first or the second input.
% Call tall/sortrows for tabular inputs and sortcomon for numeric inputs.
% Sortcommon repartitions the array so that all repeated elements end up in
% the same partition as each other. This allows us to find the unique
% elements per partition in the following part.
if isTabular
    if requiresIndexComputation
        [tableC, varNames] = iSortrowsTabularInputs(c, requiresIndexComputation, fromID, indC);
    else
        [tableC, varNames] = iSortrowsTabularInputs(c, requiresIndexComputation);
    end
else
    if requiresIndexComputation
        [tableC, varNames] = iSortrowsNonTabularInputs(c, requiresIndexComputation, isRowVectors, isARowVector, isSetdiff, fromID, indC);
    else
        [tableC, varNames] = iSortrowsNonTabularInputs(c, requiresIndexComputation, isRowVectors, isARowVector, isSetdiff);
    end
end

% Deal with the adaptors for tableC and its variables.
if isRowsOrTabular
    adaptorA = resetTallSize(adaptorA);
    adaptorB = resetTallSize(adaptorB);
else
    % If the inputs are not tabular or 'rows' mode, the small sizes cannot
    % be predicted due to possible empty inputs.
    adaptorA = resetSizeInformation(adaptorA);
    adaptorB = resetSizeInformation(adaptorB);
end
adaptorC = matlab.bigdata.internal.adaptors.combineAdaptors(1, {adaptorA, adaptorB});
varAdaptors = {adaptorC};

if requiresIndexComputation
    adaptorFromID = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    % The indices IA and IB are always column vectors of class 'double'.
    adaptorIndC = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    varAdaptors = [varAdaptors, {adaptorFromID}, {adaptorIndC}];
end
tableC.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, varAdaptors);


% Part 4. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform unique per partition on data+inputID of tableC to remove repeated
% elements in each input separately, and their corresponding indices.

if requiresIndexComputation
    % Due to sortrows, all of the repeated elements are in the same
    % partition. Find the unique elements per partition. Specify that
    % unique is computed with C and fromID.
    tableC = iUniquePerPartition(tableC, {'C', 'fromID'});
    tableC.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, varAdaptors);
else
    % For union with single output, we do not need the index computation.
    % Find directly the unique elements per partition only with the first
    % variable of tableC.
    tableC = iUniquePerPartition(tableC, {'C'});
    tableC.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, varAdaptors);
end
tableC.Adaptor = resetTallSize(tableC.Adaptor);

% Part 5. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create the resulting table that contains the following three variables:
%       - C: Unique data elements from both inputs.
%       - indA: Corresponding indices for input A. If an element does not
%         exist in input A, the corresponding index will be set to 0.
%       - indB: Corresponding indices for input B. If an element does not
%         exist in input B, the corresponding index will be set to 0.
% Except for union with a single output, where tableC is directly returned
% at this point. For this case, tableC only contains C.
if requiresIndexComputation
    fh = matlab.bigdata.internal.util.StatefulFunction(@iBuildResultTable);
    fh = matlab.bigdata.internal.FunctionHandle(fh);
    out = partitionfun(fh, tableC, numOutputs);
    
    varNames = {'C', 'indA', 'indB'};
    adaptorIndA = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    adaptorIndB = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    out.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, {adaptorC, adaptorIndA, adaptorIndB});
else
    out = subselectTabularVars(tableC, 'C');
    out.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor({'C'}, {adaptorC});
end
out = copyPartitionIndependence(out, c);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Columnize Matrices %%%%%%%%%%%%%%%%%%%%%%%%%%%
function [a, b, indA, indB, isRowVectors, isARowVector] = iColumnizeInputsAandBwithIndices(a, b, adaptorA, adaptorB, aIsTall, bIsTall, numOutputs)
% Indices required. Must columnize and find indices for all matrices. If
% only one output is requested, create a column vector for each input A and
% B that specifies the origin of each element instead of computing the
% absolute slice indices.
[isRowVectors, isARowVector] = clientfun(@(szA, szB) iCheckIfRowVectorInputs(szA, szB), ...
    size(a), size(b));

isMatrixB = false;
[a, indA] = iColumnizeWithIndices(a, adaptorA, aIsTall, isMatrixB, numOutputs);
isMatrixB = true;
[b, indB] = iColumnizeWithIndices(b, adaptorB, bIsTall, isMatrixB, numOutputs);
end

function [out, indOut] = iColumnizeWithIndices(in, adaptorIn, isTall, isMatrixB, numOutputs)
% Columnize matrices and find indices. If only one output is requested,
% create a column vector that specifies the origin of each element instead
% of computing the absolute slice indices. We also need to update the
% output adaptor after chunkfun and before sending through to tall/vertcat.
if isTall
    if numOutputs > 1
        sliceIds = getAbsoluteSliceIndices(in);
        [out, indOut] = chunkfun(@(in, sliceIds, szIn) iColumnizeMatrixWithIndices(in, sliceIds, szIn), ...
            in, sliceIds, matlab.bigdata.internal.broadcast(size(in)));
    else
        out = chunkfun(@iColumnizeMatrix, in);
        out.Adaptor = resetSizeInformation(adaptorIn);
        indOut = iCreateOriginVectorForInput(out, isTall, isMatrixB + 1);
    end
    out.Adaptor = resetSizeInformation(adaptorIn);
    indOut.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
else
    out = in(:);
    if numOutputs > 1
        indOut = (1:numel(in))';
    else
        indOut = (isMatrixB + 1)*ones(numel(in), 1);
    end
end
end

function [out, indOut] = iColumnizeMatrixWithIndices(localT, sliceIds, globalSz)
% Columnize local input and create the correct corresponding indices.
if ~isempty(localT)
    % Map indices.
    indOut = ones(size(localT));
    indOut = indOut(:);
    x = sliceIds;
    for jj = 1:numel(sliceIds):numel(indOut)
        idx = (jj-1) + (1:numel(sliceIds));
        indOut(idx) = x;
        x = x + globalSz(1);
    end
    % Call unique, so that when sort is called later it has to deal with
    % less elements.
    [out, idx] = unique(localT(:));
    indOut = indOut(idx);
else
    out = localT(:);
    indOut = zeros(0, 1);
end
end

function out = iColumnizeMatrix(blockIn)
% Columnize block of the input tall array.
out = blockIn(:);
end

function [isRowVectors, isARowVector] = iCheckIfRowVectorInputs(szA, szB)
% Check whether A and B are row vectors, this will generate the result as a
% row vector as well.
isRowVectors = szA(1) == 1 && szB(1) == 1;
% Check if only A is a row vector. For setdiff, the result will be a row
% vector is A is a row vector, regardless the shape of B.
isARowVector = szA(1) == 1;
end

%%%%%%%%%% Get Slice Indices for tall and non-tall inputs %%%%%%%%%%%%%
function idx = iGetSliceIndices(x, isTall)
% Get the slice indices for input x. If x is a row vector or a matrix, it
% has been already columnized.
if isTall
    idx = getAbsoluteSliceIndices(x);
else
    idx = (1:size(x, 1))';
end
end

%%%%%%%%%%%%%% Create origin vector for single output %%%%%%%%%%%%%%%%%
function fromIdx = iCreateOriginVectorForInput(x, isTall, value)
% For single-output cases, create an index vector with a single value for
% each of the inputs.
if isTall
    fromIdx = chunkfun(@iCreateOriginVector, x, value);
    fromIdx.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
else
    fromIdx = iCreateOriginVector(x, value);
end
end

function idx = iCreateOriginVector(x, value)
% For single-output cases, create an index vector with a single value for
% each of the inputs.
idx = value*ones(size(x, 1), 1);
end

%%%%%%%%%%%%%%%%% Call Sortrows for tabular inputs %%%%%%%%%%%%%%%%%%%%
function [tableC, varNames] = iSortrowsTabularInputs(c, requiresIndexComputation, varargin)
% Sort rows of tabular input C considering fromID and indC if indices are
% required.

if nargin == 4
    fromID = varargin{1};
    indC = varargin{2};
end

% Check that all the table variables have up to 2 dimensions.
adaptorC = c.Adaptor;
if adaptorC.Class == "table"
    numVars = numel(adaptorC.getVariableNames());
    for k = 1:numVars
        var = subsref(c, substruct('{}', {':', k}));
        var = tall.validateMatrix(var, 'MATLAB:bigdata:array:SetFcnTabularNDVar'); %#ok<NASGU>
    end
end

% Identify if indices of C are needed.
if requiresIndexComputation
    varNames = {'C', 'fromID', 'indC'};
    % Create a table with indC and a second table with fromId to
    % horizontally concatenate with input C.
    vars = {c, table(fromID, 'VariableNames', {'fromID'}), table(indC, 'VariableNames', {'indC'})};
else
    varNames = {'C'};
    vars = {c};
end

% Sortrows cannot sort tables within tables. If needed, concatenate
% indC to input table C to sort C and indC at the same time.
tC = horzcat(vars{:});

% Call iUniquePerPartition in order to reduce the amount of elements
% needed to be sent to sortrows. Specify that unique is computed with
% all the variables in C and fromID. By doing this, we eliminate
% repeated elements in each of the inputs separately.
varNamesInC = subsref(c, substruct('.', 'Properties', '.', 'VariableNames'));
if requiresIndexComputation
    tC = iUniquePerPartition(tC, [varNamesInC, {'fromID'}]);
else
    tC = iUniquePerPartition(tC, varNamesInC);
end

% Call sortrows with the updated table.
if adaptorC.Class == "timetable"
    sortFcn = @(x) sortrows(x);
else
    sortFcn = @(x) sortrows(x, varNamesInC);
end
tC = sortFcn(tC);

% Extract C, fromID and indC if needed.
c = subselectTabularVars(tC, 1:numel(varNamesInC));
if requiresIndexComputation
    fromID = subsref(tC, substruct('.', 'fromID'));
    indC = subsref(tC, substruct('.', 'indC'));
    vars = {c, fromID, indC};
else
    vars = {c};
end

% Create tableC with sorted data (and indices)
tableC = table(vars{:}, 'VariableNames', varNames);
end

%%%%%%%%%%%%%%% Call Sortrows for non-tabular inputs %%%%%%%%%%%%%%%%%%
function [tableC, varNames] = iSortrowsNonTabularInputs(c, requiresIndexComputation, isRowVectors, isARowVector, isSetdiff, varargin)
% Sort rows of non-tabular input C considering fromID and indC if indices
% are required.

if nargin > 5
    fromID = varargin{1};
    indC = varargin{2};
end

% Convert C, fromID and indC to a table.
if requiresIndexComputation
    varNames = {'C', 'fromID', 'indC'};
    vars = {c, fromID, indC};
else
    varNames = {'C'};
    vars = {c};
end
tableC = table(vars{:}, 'VariableNames', varNames);

% Call iUniquePerPartition in order to reduce the amount of elements
% needed to be sent to sortcommon. Specify that unique is computed with
% the elements in C and fromID. By doing this, we eliminate repeated
% elements in each of the inputs separately.
% Vertcat may have placed all the elements in a single partition when
% both inputs are row vectors or scalars and we could potentially
% remove repeated elements that appear once in each of the inputs.
if requiresIndexComputation
    tableC = iUniquePerPartition(tableC, {'C', 'fromID'});
else
    tableC = iUniquePerPartition(tableC, {'C'});
end

% Repartition and sort tableC. The indices will be sorted along with
% their corresponding values in C. If the inputs were row vectors, or if A
% was a row vector in setdiff, all of the elements need to be in the same
% partition. Otherwise, we only want to repartition with respect to the
% first variable of tableC.
if istall(isRowVectors) || istall(isARowVector)
    isOnePartition = clientfun(@(bothRows, rowA) bothRows || (rowA && isSetdiff), isRowVectors, isARowVector);
else
    % Both flags might be non-tall.
    isOnePartition = isRowVectors || (isARowVector && isSetdiff);
end
sortFcn = @(t) sortCommon(@(x) sortrows(x), t, 'AllInOnePartition', isOnePartition, 'PartitionWrtColumn', 1);

tableC = sortFcn(tableC);
end

%%%%%%%%%%%%%%%%%%%%%%% Unique Per Partition %%%%%%%%%%%%%%%%%%%%%%%%%%
function tY = iUniquePerPartition(tX, smallIdx)
% Perform a unique rows operation across each individual partition. We can
% assume that the elements are already sorted and in the correct partition
% due to tall/sortrows.
% Only take the variables given by smallIdx to perform unique.
fh = matlab.bigdata.internal.util.StatefulFunction(@iUniquePerPartitionImpl);
fh = matlab.bigdata.internal.FunctionHandle(fh);
tY = partitionfun(fh, tX, smallIdx);
tY.Adaptor = resetTallSize(tX.Adaptor);
tY = copyPartitionIndependence(tY, tX);
end

function [state, isFinished, t, smallIdx] = iUniquePerPartitionImpl(state, info, t, smallIdx)
% Performs a unique operation with respect to the variables of t given by
% smallIdx. When repeated elements are found in a certain row, the entire
% row is removed from the table.

isFinished = info.IsLastChunk;

if ~isempty(state)
    t = [state; t];
end

% Find the repeated elements with all the variables given by smallIdx.
[~, idx] = unique(t(:, smallIdx), 'rows');
% Remove the entire row corresponding to where the repeated elements were
% found in the first column of table t.
t = t(idx, :);

state = [];
if ~isFinished && ~isempty(t)
    state = t(end, :);
    t(end, :) = [];
end
end

%%%%%%%%%%%%%%%%%%%%%%% Build result table %%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [state, isFinished, tOut, numOutputs] = iBuildResultTable(state, info, t, numOutputs)
% Redistribute the information in t (C, indC and fromID) to a final result
% table with the following variables:
%       - C: Unique data elements from both inputs.
%       - indA: Corresponding indices for input A. If an element does not
%         exist in input A, the corresponding index will be set to 0.
%       - indB: Corresponding indices for input B. If an element does not
%         exist in input B, the corresponding index will be set to 0.
% In order to do so, get the unique set of data from both inputs in the
% variable C of tableC. Then, redistribute the indices from variable indC
% in tableC into two separate variables: indA and indB.

isFinished = info.IsLastChunk;

if ~isempty(state)
    t = [state; t];
end

% Distribute data and indices to the result table. Assign the indices in
% indC to the corresponding data element in C. If an element does not exist
% in one of the inputs, the corresponding index is set to 0.
varNames = {'C', 'indA', 'indB'};
if ~isempty(t.C) || ~isempty(t.indC)
    % Get unique values in C to include them in the result
    if ~iscell(t.C)
        [outC, ~, idxC] = unique(t.C, 'rows');
    else
        [outC, ~, idxC] = unique(t.C);
    end
    % Use unstack to distribute the indices in indC according to the origin
    % in fromID. Use idxC from unique as the grouping variable for unstack.
    tAndIdxC = addvars(t, idxC);
    if all(t.fromID == 1)
        % All the elements in this chunk come from the first input.
        % Unstack will only return indA.
        tNew = unstack(tAndIdxC, 'indC', 'fromID', ...
            'GroupingVariables', 'idxC', ...
            'NewDataVariableNames', {'indA'});
        % Remove the grouping variable idxC and add the unique set of
        % elements to the final result.
        tNew = removevars(tNew, 'idxC');
        tOut = addvars(tNew, outC, 'Before', 1, 'NewVariableNames', {'C'});
        % Create indB as a vector of zeros and add it to the table
        tOut = addvars(tOut, zeros(size(tOut, 1), 1), 'NewVariableNames', {'indB'});
    elseif all(t.fromID == 2)
        % All the elements in this chunk come from the second input.
        % Unstack will only return indB.
        tNew = unstack(tAndIdxC, 'indC', 'fromID', ...
            'GroupingVariables', 'idxC', ...
            'NewDataVariableNames', {'indB'});
        % Remove the grouping variable idxC and add the unique set of
        % elements to the final result.
        tNew = removevars(tNew, 'idxC');
        tOut = addvars(tNew, outC, 'Before', 1, 'NewVariableNames', {'C'});
        % Create indA as a vector of zeros and add it to the table
        tOut = addvars(tOut, zeros(size(tOut, 1), 1), 'After', 1, 'NewVariableNames', {'indA'});
    else
        % This chunk contains elements from both inputs. Unstack returns
        % indices in indA and indB. If they do not exist in one of the
        % outputs, they are set to NaN.
        tNew = unstack(tAndIdxC, 'indC', 'fromID', ...
            'GroupingVariables', 'idxC', ...
            'NewDataVariableNames', varNames(2:3));
        % Replace NaNs ind indA and indB with zeros
        tNew(:, varNames(2:3)) = fillmissing(tNew(:, varNames(2:3)), 'constant', 0);
        % Remove the grouping variable idxC and add the unique set of
        % elements to the final result.
        tNew = removevars(tNew, 'idxC');
        tOut = addvars(tNew, outC, 'Before', 1, 'NewVariableNames', varNames(1));
    end
else
    % Create empty output table for this chunk. Take an empty slice from t to
    % keep the size of empty C variables.
    tOut = matlab.bigdata.internal.util.indexSlices(t, []);
    tOut.Properties.VariableNames = varNames;
end

if ~isFinished && ~isempty(tOut) && t{end, 'fromID'} == 1
    % At this point, the first variable C in t is ordered. It is also
    % guaranteed that all the elements that exist in both inputs appear
    % here in order. The first appearance in t has the indices from A and
    % the second appearance has the indices from B.
    % Save the state only when the last element in the input chunk of t
    % contains data from the first input. Remove the last row of tOut
    % as the corresponding result will be emitted by the following
    % chunk.
    state = t(end, :);
    tOut(end, :) = [];
else
    state = [];
end
end