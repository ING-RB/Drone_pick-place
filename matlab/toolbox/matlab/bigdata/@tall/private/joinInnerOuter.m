function varargout = joinInnerOuter(joinType,tA,tB,Aname,Bname,varargin)
%joinInnerOuter Shared implementation of tall innerjoin and tall outerjoin.
%   [C,IA,IB] = joinInnerOuter('innerjoin',A,B,...)
%   [C,IA,IB] = joinInnerOuter('outerjoin',A,B,...)

%   Copyright 2019-2023 The MathWorks, Inc.

narginchk(5,Inf);
fcnName = upper(joinType);
[tA,tB] = tall.validateType(tA,tB,fcnName,{'table','timetable'},1:2);
tall.checkNotTall(fcnName,2,varargin{:});

% Use joinBySample to create an appropriate adaptor for the output. We do
% this first as it provides the actual variable names and some quick input
% parsing/error checking. We don't want to repeat this same work per chunk.
% For example, this is where we error for the table-timetable combination.
adaptorA = matlab.bigdata.internal.adaptors.getAdaptor(tA);
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(tB);
requiresVarMerging = true;
if isequal(joinType,'outerjoin')
    fcnHandle = @outerjoin;
else
    fcnHandle = @innerjoin;
end
[adaptorOut,varNames] = joinBySample(...
    @(A, B) joinNamedTables(fcnHandle,A,B,Aname,Bname,varargin{:}),...
    requiresVarMerging,adaptorA,adaptorB);

% Always compute tall to tall innerjoin or outerjoin because the tall
% output must be sorted by all the keys in tA and tB.
if ~istall(tA)
    tA = tall.createGathered(tA,getExecutor(tB));
end
if ~istall(tB)
    tB = tall.createGathered(tB,getExecutor(tA));
end

% Now schedule the actual work.
[varargout{1:nargout}] = iTallToTallInnerOuterJoin(joinType,tA,tB,...
    varNames,adaptorOut,varargin{:});
end

function [tC,tIA,tIB] = iTallToTallInnerOuterJoin(joinType,tA,tB,...
    varNamesOut,adaptorOut,varargin)
% Inner or outer join between two tall (time)tables

% 'LeftKeys', 'RightKeys', 'LeftVariable', and 'RightVariables' indices.
[keysIndA,keysIndB,varsIndA,varsIndB,outerType,outerMergeKeys] = ...
    joinGetKeyVars(joinType,tA.Adaptor,tB.Adaptor,varargin{:});

% Extract tall key data.
[tKeysA,tKeysB,keyNamesA,keyNamesB] = joinGetKeyData(joinType,tA,tB,...
    keysIndA,keysIndB);

% Compute the IA and IB inner/outerjoin indices (second and third outputs).
[tIA,tIB] = iComputeIndices(joinType,tA,tB,tKeysA,tKeysB,...
    numel(keysIndA),outerType);

% Permute and concatenate A and B according to IA and IB.
tC = iPermuteAndHorzcat(joinType,tA,tB,tIA,tIB,keysIndA,keysIndB,...
    keyNamesA,keyNamesB,outerMergeKeys,varsIndA,varsIndB,...
    varNamesOut,adaptorOut);

if nargout > 1 && isequal(joinType,'outerjoin')
    % Undo our earlier outerjoin trick of adding 1 to the indices.
    tIA = elementfun(@(x)x-1,tIA); % tIA = tIA - 1
    if nargout > 2
        tIB = elementfun(@(x)x-1,tIB);
    end
end
end

function [tIA,tIB] = iComputeIndices(joinType,tA,tB,tKeysA,tKeysB,...
    nKeys,outerType)
% Compute the IA and IB inner/outerjoin indices (second and third outputs).

% Vertcat and sort the keys of A and B into a table. Also attach absolute
% indices in A and B to track the original position of the keys in A and B.
tSortedKeysAB = [table(tKeysA{:}); table(tKeysB{:})];
% [(1:size(tA,1))'; (1:size(tB,1))']
tIndsAB = [getAbsoluteSliceIndices(tA); getAbsoluteSliceIndices(tB)];
% [ones(size(tA,1),1); 2*ones(size(tB,1),1)]
tFromAB = [iOnesColumn(tA,1); iOnesColumn(tB,2)];
tSortedKeysAB = subsasgn(tSortedKeysAB,substruct('.',nKeys+1),tIndsAB);
tSortedKeysAB = subsasgn(tSortedKeysAB,substruct('.',nKeys+2),tFromAB);
tSortedKeysAB = sortrows(tSortedKeysAB,1:nKeys);

% Compute the inner/outerjoin indices IA and IB from the sorted keys.
% sortrows guarantees that duplicate keys are in the same partition.
% Thus, we can simply wrap in-memory inner/outerjoin into a partitionfun.
tIAIB = partitionfun(@iComputeIndicesKernel,tSortedKeysAB,...
    matlab.bigdata.internal.broadcast(joinType),...
    matlab.bigdata.internal.broadcast(nKeys),...
    matlab.bigdata.internal.broadcast(outerType));
tIAIB = copyPartitionIndependence(tIAIB,tSortedKeysAB);

% Extract the indices from the table.
adaptorInds = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
tIAIB.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(...
    {'IA','IB'},{adaptorInds,adaptorInds});
tIA = subsref(tIAIB,substruct('.','IA'));
tIB = subsref(tIAIB,substruct('.','IB'));
end

function tB = iOnesColumn(tA,value)
% size(tA,1) - by - 1 column of ones (or some other constant value).
tB = chunkfun(@(A,v) v * ones(size(A,1),1), ...
    tA,matlab.bigdata.internal.broadcast(value));
tB.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
tB.Adaptor = copyTallSize(tB.Adaptor,tA.Adaptor);
tB.Adaptor = resetSmallSizes(tB.Adaptor,1);
end

function [isFinished,tIAIB] = iComputeIndicesKernel(info,tSortedKeysAB,...
    joinType,nKeys,outerType)
% Match up the keys of A and B to compute (local) inner/outerjoin indices.
% The input tSortedKeysAB contains the sorted keys obtained from:
%   sortrows(table([keysA; keysB],[indsA; indsB],[fromA; fromB]),1:nKeys)
isFinished = info.IsLastChunk;

fromA = tSortedKeysAB.(nKeys+2) == 1;
sortedKeysA = tSortedKeysAB(fromA,1:nKeys+1);  % [sortedKeysA indsA]
sortedKeysB = tSortedKeysAB(~fromA,1:nKeys+1); % [sortedKeysB indsB]

% sortrows guarantees that duplicate keys are in the same partition.
% Therefore, we can re-use the in-memory implementation to extract the
% correct indices for matched and mismatched (including missing) keys.
% We don't need to return the keys, just keep the inner/outerjoin indices.
if isequal(joinType,'outerjoin')
    tIAIB = outerjoin(sortedKeysA,sortedKeysB,'Keys',1:nKeys,...
        'LeftVariables',nKeys+1,'RightVariables',nKeys+1,'Type',outerType);
else
    tIAIB = innerjoin(sortedKeysA,sortedKeysB,'Keys',1:nKeys,...
        'LeftVariables',nKeys+1,'RightVariables',nKeys+1);
end
tIAIB.Properties.VariableNames = {'IA','IB'};

if isequal(joinType,'outerjoin')
    % Set outerjoin indices to 0 for mismatched keys.
    tIAIB.IA(isnan(tIAIB.IA)) = 0;
    tIAIB.IB(isnan(tIAIB.IB)) = 0;
    % And, while we are here, offset outerjoin indices by 1 so that the 0
    % outerjoin indices become 1 and we can index with them later.
    tIAIB.IA = tIAIB.IA + 1;
    tIAIB.IB = tIAIB.IB + 1;
end
end

function tC = iPermuteAndHorzcat(joinType,tA,tB,tIA,tIB,keysIndA,...
    keysIndB,keyNamesA,keyNamesB,outerMergeKeys,varsIndA,varsIndB,...
    varNamesOut,adaptorOut)
% Permute and concatenate A and B according to the IA and IB indices to get
% the final inner/outerjoin result.
%   C = [A(IA,varsIndA) B(IB,varsIndB)]
% where varsIndA also contains the key variables and varsIndB doesn't.
import matlab.bigdata.internal.broadcast;
nVarsA = numel(varsIndA);
nVarsB = numel(varsIndB);

if isequal(joinType,'outerjoin')
    % Outerjoin missing Time keys need special care to produce the correct
    % Time in the output. We need this only for timetable-timetable, since
    % outerjoin does not support the table-timetable combination.
    fixMissingTime = any(keysIndA == 0);
    mergeTimeOrKeys = fixMissingTime || outerMergeKeys;
    
    % Some keys may not be part of LeftVariables and RightVariables. Put
    % them back in, so that our trick of calling in-memory outerjoin to
    % merge the keys works correctly.
    keysToMergeSansTimeA = keyNamesA(keysIndA ~= 0);
    keysToMergeSansTimeB = keyNamesB(keysIndB ~= 0);
    varNamesA = getVariableNames(tA.Adaptor);
    varNamesB = getVariableNames(tB.Adaptor);
    varsIndA = unique([varNamesA(varsIndA) keysToMergeSansTimeA],'stable');
    varsIndB = unique([varNamesB(varsIndB) keysToMergeSansTimeB],'stable');
end

% A(:,varsIndA) and B(:,varsIndB) preserve metadata (VariableContinuity).
tFromA = subselectTabularVars(tA,varsIndA);
tFromB = subselectTabularVars(tB,varsIndB);

if isequal(joinType,'outerjoin')
    % Recall that we made IA = 1 and IB = 1 correspond to mismatched keys.
    % Prepend one row (the first row) with missing data so that indexing
    % with IA and IB will propagate this missing data in the right places
    % for outerjoin, i.e., in the places corresponding to mismatched keys.
    tFromA = iOuterjoinPrependMissingDataRow(tFromA);
    tFromB = iOuterjoinPrependMissingDataRow(tFromB);
end

% Permute the rows according to the sorted keys.
tFromAPermuted = subsref(tFromA,substruct('()',{tIA,':'}));
tFromBPermuted = subsref(tFromB,substruct('()',{tIB,':'}));

tFromA = subselectTabularVars(tFromAPermuted,1:nVarsA);
tFromB = subselectTabularVars(tFromBPermuted,1:nVarsB);

if isequal(tB.Adaptor.Class,'timetable')
    % Convert B to table because we cannot concatenate timetables with
    % missing times. Use the time of A -- it is already in the correct one.
    tFromB = timetable2table(tFromB,'ConvertRowTimes',false);
end

% Copy over the correct variable names so that horzcat doesn't error if A
% and B have variables with the same name.
subsVarNames = substruct('.','Properties','.','VariableNames');
tFromA = subsasgn(tFromA,subsVarNames,varNamesOut(1:nVarsA));
tFromB = subsasgn(tFromB,subsVarNames,varNamesOut(nVarsA + (1:nVarsB)));

% Concatenate the variables. No need for alignpartitions(tA,tB) because tIA
% and tIB are already aligned.
tC = [tFromA, tFromB];

% HORZCAT and JOIN disagree about which input determines the output
% dimension names, so correct that now. JOIN uses dimension names from the
% first input.
subsDimNames = substruct('.','Properties','.','DimensionNames');
tC = subsasgn(tC, subsDimNames, getDimensionNames(adaptorOut));

if isequal(joinType,'outerjoin') && mergeTimeOrKeys
    % Mismatched key values have not been merged correctly. Fix this.
    tC = slicefun(@iOuterjoinMergeTimeAndKeys,tC,tFromAPermuted,...
        tFromBPermuted,tIA,broadcast(nVarsA),broadcast(nVarsB),...
        broadcast(keyNamesA),broadcast(keyNamesB),...
        broadcast(outerMergeKeys));
end

if ~isequal(joinType,'outerjoin')
    % Merge key metadata for join and innerjoin
    tC = elementfun(@matlab.bigdata.internal.adaptors.fixTabularPropertyMetadata,...
        tC,broadcast(adaptorOut));
end

tC.Adaptor = adaptorOut;
end

function tA = iOuterjoinPrependMissingDataRow(tA)
% Prepend one row (the first row) with missing data so that indexing with
% IA and IB will propagate this missing data in the right places for
% outerjoin, i.e., in the places corresponding to mismatched keys.

tRowOfMissingDataA = clientfun(@iOuterjoinMissingDataTableRow,head(tA,0));
tRowOfMissingDataA.Adaptor = setTallSize(resetTallSize(tA.Adaptor),1);

% We can just vertcat because they have the same variable names and types.
tA = [tRowOfMissingDataA; tA];
end

function tRowOfMissingDataA = iOuterjoinMissingDataTableRow(tZeroRowsTable)
% Leverage outerjoin on a temporary missing key to create a table row of
% missing data of appropriate type from a table with zero rows. Use N-V
% pairs such that the output does not include the temporary key variables.
n = width(tZeroRowsTable);
tZeroRowsTable{:,n+1} = zeros(0,1);
tRowOfMissingDataA = outerjoin(tZeroRowsTable,table(NaN),...
    'LeftKeys',n+1,'RightKeys',1,'LeftVariables',1:n,'RightVariables',{});
end

function tC = iOuterjoinMergeTimeAndKeys(tC,tFromAPermuted,...
    tFromBPermuted,tIA,nVarsA,nVarsB,keyNamesA,keyNamesB,outerMergeKeys)
% Mismatched Time and/or key values have not been merged correctly. Fix it
% by calling in-memory left- or right- outerjoin on each (time)table row to
% avoid duplication of the complicated key merging code.
for k = 1:height(tFromAPermuted)
    % Recall that we made IA = 1 and IB = 1 correspond to mismatched keys.
    if tIA(k) == 1
        t = 'right';
    else
        t = 'left';
    end
    % Overwrite mismatched keys by keeping the first row from a left- or
    % right- outerjoin result. If we knew exactly which key values were
    % mismatched, we could set the 'LeftVariables' and 'RightVariables' to
    % be the same as the keys and, thus, do less computation per row.
    temp = outerjoin(tFromAPermuted(k,:),tFromBPermuted(k,:),'Type',t,...
        'MergeKeys',outerMergeKeys,'LeftKeys',keyNamesA,'RightKeys',...
        keyNamesB,'LeftVariables',1:nVarsA,'RightVariables',1:nVarsB);
    tC(k,:) = temp(1,:);
    if istimetable(tFromAPermuted)
        tC.(tC.Properties.DimensionNames{1})(k) = ...
            temp.(temp.Properties.DimensionNames{1})(1);
    end
end
end
