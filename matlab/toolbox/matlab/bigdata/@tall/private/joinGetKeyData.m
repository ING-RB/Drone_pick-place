function [tKeysA,tKeysB,keyNamesA,keyNamesB] = ...
    joinGetKeyData(joinType,tA,tB,varIndsA,varIndsB)
% joinGetKeyData Extract join, innerjoin, and outerjoin tall key data.
% Extract tall table variable data into a cell, including row labels/time.

%   Copyright 2018-2019 The MathWorks, Inc.

adaptorA = tA.Adaptor;
adaptorB = tB.Adaptor;
dimNamesA = getDimensionNames(adaptorA); % 'Time'
dimNamesB = getDimensionNames(adaptorB); % 'Time'
varNamesA = getVariableNames(adaptorA);
varNamesB = getVariableNames(adaptorB);
n = numel(varIndsA); % = numel(varIndsB)
tKeysA = cell(1,n);
tKeysB = cell(1,n);
keyNamesA = cell(1,n);
keyNamesB = cell(1,n);
for k = 1:n
    % Extract variable data.
    keyNamesA{k} = iGetVarOrRowLabelName(dimNamesA,varNamesA,varIndsA(k));
    keyNamesB{k} = iGetVarOrRowLabelName(dimNamesB,varNamesB,varIndsB(k));
    tKeysA{k} = subsref(tA,substruct('.',keyNamesA{k}));
    tKeysB{k} = subsref(tB,substruct('.',keyNamesB{k}));
    % Check and cast if the key types are compatible.
    [tKeysA{k},tKeysB{k}] = iMatchType(joinType,tKeysA{k},tKeysB{k},...
        keyNamesA{k},keyNamesB{k});
end
end

function varName = iGetVarOrRowLabelName(dimNames,varNames,varInd)
% Get variable name or row label/time name from non-negative numeric index.
if varInd == 0
    varName = dimNames{1}; % A.Properties.DimensionNames{1}
else
    varName = varNames{varInd}; % A.Properties.VariableNames{varInd}
end
end

function [tA,tB] = iMatchType(joinType,tA,tB,nameA,nameB)
% Check and cast if the key types are compatible by matching the in-memory
% behavior (and error message) of trying to concatenate them.
import matlab.bigdata.internal.adaptors.getAdaptor;
import matlab.bigdata.internal.adaptors.combineAdaptors;
import matlab.bigdata.internal.broadcast;
adaptorA = getAdaptor(tA);
adaptorB = getAdaptor(tB);
try
    adaptor = combineAdaptors(1,{adaptorA,adaptorB});
catch
    % "Left and right key variables {0} and {1} have incompatible types."
    error(message('MATLAB:table:join:KeyVarTypeMismatch',nameA,nameB));
end

flippedAandB = false; % Makes sure tB has the same type as tA for integers.
tA = slicefun(@iMatchTypeImpl,broadcast(joinType),tA,...
    broadcast(head(tB,0)),broadcast(nameA),broadcast(nameB),...
    broadcast(flippedAandB));
tA.Adaptor = copyTallSize(adaptor,adaptorA);

tB = slicefun(@iMatchTypeImpl,broadcast(joinType),tB,...
    broadcast(head(tA,0)),broadcast(nameB),broadcast(nameA),...
    broadcast(~flippedAandB));
tB.Adaptor = copyTallSize(adaptor,adaptorB);
end

function A = iMatchTypeImpl(joinType,A,emptyB,nameA,nameB,flippedAandB)
try
    % For integer types, the concatenation order dictates the output type,
    % e.g., [int8([]); int16(1)] vs. [int16(1); int8([])], so we have to be
    % careful to match the in-memory concatenation order of [keyA; keyB].
    if ~flippedAandB
        A = [A; emptyB];
    else
        A = [emptyB; A];
    end
catch
    % "Left and right key variables {0} and {1} have incompatible types."
    error(message('MATLAB:table:join:KeyVarTypeMismatch',nameA,nameB));
end

if isequal(joinType,'join')
    % While we're here, also check for missing keys.
    if any(ismissing(A),'all')
        error(message('MATLAB:table:join:MissingKeyValues'));
    end
end
end
