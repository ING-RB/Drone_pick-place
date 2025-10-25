function [leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,outMetaDim] ...
    = joinUtil(a,b,type,~,~, ...
    keys,leftKeysIn,rightKeysIn,leftVarsIn,rightVarsIn,keepOneCopy,mergeKeys,supplied) %#codegen
%JOINUTIL Common set-up for join, innerjoin, and outerjoin.

%   Copyright 2020-2022 The MathWorks, Inc.

coder.extrinsic('find', 'getString', 'intersect', 'ismember', 'matches', 'matlab.internal.i18n.locale', 'message', 'namelengthmax', 'setdiff', 'strjoin');

if supplied.Keys
    keys = convertStringsToChars(keys);
    coder.internal.errorIf(supplied.LeftKeys || supplied.RightKeys,'MATLAB:table:join:ConflictingInputs')
    if isequal(keys,'RowNames') ...
            && type == "simple" && isa(a,'table') && isa(b,'table')
        % The reserved name 'RowLabels' is a compatibility special case only for simple
        % joins between two tables.
        a.throwSubclassSpecificErrorIf(~(a.rowDim.hasLabels && b.rowDim.hasLabels),'NoRowLabels');
        leftKeys = 0;
        rightKeys = 0;
    else
        leftKeys = a.getVarOrRowLabelIndices(keys);
        rightKeys = b.getVarOrRowLabelIndices(keys);
        coder.internal.errorIf(isempty(leftKeys) || isempty(rightKeys),'MATLAB:table:InvalidVarSubscript');
    end
else % ~supplied.Keys
    if ~supplied.LeftKeys && ~supplied.RightKeys
        % Default join behavior when no keys specified
        if isa(a,'timetable') && isa(b,'timetable')
            % Join by row times
            leftKeys = 0;
            rightKeys = 0;
        else % at least one is a table
            % Join by vars with common names
            [leftKeys,rightKeys] = coder.const(@ismember,a.varDim.labels,b.varDim.labels);
            leftKeys = coder.const(find(leftKeys));
            rightKeys = rightKeys(rightKeys>0);
            coder.internal.errorIf(isempty(leftKeys),'MATLAB:table:join:CantInferKey');
        end
    else
        coder.internal.errorIf(~supplied.LeftKeys || ~supplied.RightKeys,'MATLAB:table:join:MissingKeyVar');
        % Make sure the keys exist in both sides.
        leftKeys = a.getVarOrRowLabelIndices(leftKeysIn);
        rightKeys = b.getVarOrRowLabelIndices(rightKeysIn);

        coder.internal.errorIf(length(leftKeys) ~= length(rightKeys),'MATLAB:table:join:UnequalNumKeyVars');
        coder.internal.errorIf(isempty(leftKeys) || isempty(rightKeys),'MATLAB:table:InvalidVarSubscript');
    end
end
coder.internal.assert(all(arrayfun(@(x)coder.internal.isIntScalar(x) && x>=0,leftKeys)),'MATLAB:badsubscript','Array indices must be positive integers or logical values.');
coder.internal.assert(all(arrayfun(@(x)coder.internal.isIntScalar(x) && x>=0,rightKeys)),'MATLAB:badsubscript','Array indices must be positive integers or logical values.');

if type ~= "simple" % {'inner' 'left' 'right' 'full'}
    % Simple joins require a unique match on the right for each row on the left,
    % so row labels in the output can simply be copied from the left (when present)
    % and there are no issues with required uniqueness.
    %
    % Inner/outer joins with a table as the first input have some restrictions to
    % avoid situations where the row labels would have to be replicated in the
    % output, but can't be without an expensive deduplication.
    if a.rowDim.requireUniqueLabels
        % The timetable must come first in a mixed-type inner/outer join.
        coder.internal.assert(b.rowDim.requireUniqueLabels,'MATLAB:table:join:TableTimetableNotSupported');
        if type ~= "inner" % {'left' 'right' 'full'}
            % Row labels cannot be mixed with other keys in a table/table outer join.
            coder.internal.errorIf((any(leftKeys == 0) && any(leftKeys > 0)) ...
                    || (any(rightKeys == 0) && any(rightKeys > 0)), ...
                    'MATLAB:table:join:TableOuterRowLabelsOtherKeysNotSupported');
        end
    end
end

% Use all vars from A and B by default, or use the specified vars.
if supplied.LeftVariables
    leftVars = validateDataVars(a,leftVarsIn);
else
    leftVars = 1:a.varDim.length;
end
if supplied.RightVariables    
    rightVarsTmp = validateDataVars(b,rightVarsIn);
else
    if strcmp(type,'simple') || strcmp(type,'inner')
        % Leave B's keys out of the right data vars for simple/inner joins, they
        % are identical to A's keys, which are already included (unless otherwise
        % specified). Row labels are never allowed as a data variable, so no need
        % to worry about removing that from rightVars. In an outer join, row label
        % keys from the right are always merged, and non-row-labels keys are
        % included unless otherwise specified.
        rightVarsTmp = 1:b.varDim.length;
        rightVarsTmp = coder.const(setdiff(rightVarsTmp,rightKeys(rightKeys>0),'sorted'));
    else
        rightVarsTmp = 1:b.varDim.length;
    end
end

% Detect and resolve duplicate var names.
leftVarDimTmp = a.varDim.selectFrom(leftVars);
rightVarDimTmp1 = b.varDim.selectFrom(rightVarsTmp);
rightVarNamesTmp = coder.const(rightVarDimTmp1.labels);
[dupsTmp1,~,ib] = coder.const(@intersect,leftVarDimTmp.labels,rightVarNamesTmp);
if supplied.KeepOneCopy && ~isempty(dupsTmp1)
    [~,keepOneCopy] = coder.const(@intersect,dupsTmp1,keepOneCopy);
    dropFromB = ib(keepOneCopy);
    rightVars = rightVarsTmp;
    rightVars = coder.const(setdiff(rightVars,rightVars(dropFromB)));
    rightVarNames = coder.const(rightVarNamesTmp);
    rightVarNames = coder.const(setdiff(rightVarNames,coder.const(subsrefParens(rightVarNames,dropFromB))));
    rightVarDimTmp2 = rightVarDimTmp1.deleteFrom(dropFromB);
    dupsTmp2 = coder.const(intersect(leftVarDimTmp.labels,rightVarNames));
    dups = coder.const(dupsTmp2);
else
    rightVarDimTmp2 = rightVarDimTmp1;
    dups = dupsTmp1;
    rightVars = coder.const(rightVarsTmp);
    rightVarNames = rightVarNamesTmp;
end

leftVarsAndKeys = [leftVars leftKeys];
for i = 1:length(leftVarsAndKeys)
    if leftVarsAndKeys(i) ~= 0 && mod(leftVarsAndKeys(i),1) == 0
        coder.internal.errorIf(isa(a.data{leftVarsAndKeys(i)},'tabular'),'MATLAB:table:join:CantJoinTabularVariable',a.varDim.labels{leftVarsAndKeys(i)});
    end
end
rightVarsAndKeys = [rightVars rightKeys];
for i = 1:length(rightVarsAndKeys)
    if rightVarsAndKeys(i) ~= 0 && mod(rightVarsAndKeys(i),1) == 0
        coder.internal.errorIf(isa(b.data{rightVarsAndKeys(i)},'tabular'),'MATLAB:table:join:CantJoinTabularVariable',b.varDim.labels{rightVarsAndKeys(i)});
    end
end

% Identify the output metaDim and detect conflicts between var names and dim
% names. For simple join we always use the dim names from the left input
% (a), however, for inner and outer join we choose the first non-default dim
% names as the output dim names. If these output dim names conflict with the
% var names of the other input, then update the dup indices for that
% particular input.
if type ~= "simple" ...
   && isequal(a.metaDim.labels,a.defaultDimNames) ...
   && ~isequal(b.metaDim.labels,b.defaultDimNames)
    outMetaDim = b.metaDim;
    outDimNames = outMetaDim.labels;
    dupsTmp2 = coder.const(intersect(leftVarDimTmp.labels,outDimNames));
    dups = coder.const(feval('unique',coder.const(feval('horzcat',dups,dupsTmp2))));
else
    outMetaDim = a.metaDim;
    outDimNames = outMetaDim.labels;
    dupsTmp2 = coder.const(intersect(rightVarNames,outDimNames));
    dups = coder.const(feval('unique',coder.const(feval('horzcat',dups,dupsTmp2))));
end

% Error for duplicate variable names (and/or duplicate key names for
% outerjoin(__,'MergeKeys',false) )
if ~isempty(mergeKeys) % caller is outerjoin
    nonRowLeftKeysLabels = getVarOrRowLabelsNames(a,leftKeys(leftKeys>0));
    nonRowRightKeysLabels = getVarOrRowLabelsNames(b,rightKeys(rightKeys>0));
    commonNonRowKeysLabels = coder.const(intersect(nonRowLeftKeysLabels,nonRowRightKeysLabels));
    leftVarsLabels = coder.const(setdiff(getVarOrRowLabelsNames(a,leftVars(leftVars > 0)),commonNonRowKeysLabels));
    rightVarsLabels = coder.const(setdiff(getVarOrRowLabelsNames(b,rightVars(rightVars > 0)),commonNonRowKeysLabels));
    if ~(mergeKeys || strcmp(type,'inner'))
        % Error if using non row dimension keys of the same name without merging keys AND including the unmerged keys in left and right variables.
        commonNonRowKeysLabelsInLeftVars = coder.const(setdiff(getVarOrRowLabelsNames(a,leftVars(leftVars > 0)),leftVarsLabels));
        commonNonRowKeysLabelsInRightVars = coder.const(setdiff(getVarOrRowLabelsNames(b,rightVars(rightVars > 0)),rightVarsLabels));
        commonNonRowKeysLabelsInOutputVars = coder.const(intersect(commonNonRowKeysLabelsInLeftVars,commonNonRowKeysLabelsInRightVars));
        coder.internal.errorIf(~isempty(commonNonRowKeysLabelsInOutputVars),'MATLAB:table:join:DuplicateUnmergedKeyVarNames');
        coder.internal.assert(isempty(dups),'MATLAB:table:join:DuplicateNonKeyVarNames');
    else
        coder.internal.errorIf(any(coder.const(matches(leftVarsLabels,rightVarsLabels))),'MATLAB:table:join:DuplicateNonKeyVarNames');
    end
else % caller is join or innerjoin
    coder.internal.assert(isempty(dups),'MATLAB:table:join:DuplicateNonKeyVarNames');
end
leftVarDim = a.varDim.selectFrom(leftVars);
rightVarDim = rightVarDimTmp2;

if isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
    % When row labels are unique, a simple join on them can be done quickly with
    % ismember. First set the right key values to the right's row indices.
    rightKeyVals = 1:b.rowDim.length;
    % Use ismember to find the left's row labels in the right's, the locations are the
    % left key values, and conveniently specify which rows in the right match the left.
    if coder.internal.isConst(a.rowDim.labels) && coder.internal.isConst(b.rowDim.labels)
        [tf,leftKeyVals] = coder.const(@ismember,a.rowDim.labels,b.rowDim.labels);
    else
        [tf,leftKeyVals] = matlab.internal.coder.datatypes.cellstr_ismember(a.rowDim.labels,b.rowDim.labels);
    end
    % As with any simple join, the right's row labels must be a superset of the left's.
    coder.internal.assert(all(tf),'MATLAB:table:join:UnequalRowNames');

else
    % Get the key var values, and check that they are scalar-valued or
    % vector-valued.
    leftKeyVals = a.getVarOrRowLabelData(leftKeys);
    rightKeyVals = b.getVarOrRowLabelData(rightKeys);
    for i = 1:length(leftKeyVals)
        coder.internal.errorIf(coder.internal.ndims(leftKeyVals{i}) > 2,'MATLAB:table:join:NDKeyVar');
    end
    for i = 1:length(rightKeyVals)
        coder.internal.errorIf(coder.internal.ndims(rightKeyVals{i}) > 2,'MATLAB:table:join:NDKeyVar');
    end

    % Convert possibly multiple keys to a single integer-valued key, taking on
    % comparable values across A and B.
    nkeys = length(leftKeys);
    leftlen = size(a,1);
    rightlen = size(b,1);
    lrkeys = zeros(leftlen+rightlen,nkeys);
    coder.unroll()
    for j = 1:nkeys
        % already know these are 2-D
        coder.internal.errorIf(size(leftKeyVals{j},2) ~= size(rightKeyVals{j},2),'MATLAB:table:join:KeyVarSizeMismatch', getVarOrRowLabelsName(a,leftKeys(j)), getVarOrRowLabelsName(b,rightKeys(j)));
        coder.internal.errorIf(iscell(leftKeyVals{j}) ~= iscell(rightKeyVals{j}),'MATLAB:table:join:KeyVarCellMismatch', getVarOrRowLabelsName(a,leftKeys(j)), getVarOrRowLabelsName(b,rightKeys(j)));
        if ~iscell(leftKeyVals{j}) || ~iscell(rightKeyVals{j})
            lrkey_j = [leftKeyVals{j}; rightKeyVals{j}];
        else
            lrkey_j = matlab.internal.coder.datatypes.cell_vertcat(leftKeyVals{j},rightKeyVals{j});
        end
        if size(lrkey_j,2) > 1
            coder.internal.assert(isnumeric(lrkey_j) || islogical(lrkey_j) || isstring(lrkey_j) || ischar(lrkey_j),'MATLAB:table:join:MulticolumnKeyVar', class(lrkey_j));
            [~,~,lrkeys(:,j)] = unique(lrkey_j,'rows');
            if ischar(lrkey_j)
                % Blank char rows are considered missing in a table variable.
                areMissing = ismissing(lrkey_j,' ');
            else
                areMissing = ismissing(lrkey_j);
            end
        else
            if ~iscell(lrkey_j)
                [~,~,lrkeys(:,j)] = unique(lrkey_j(:));
                if ischar(lrkey_j)
                    % Blank char rows are considered missing in a table variable.
                    areMissing = ismissing(lrkey_j,' ');
                else
                    areMissing = ismissing(lrkey_j);
                end
            else
                coder.internal.assert(iscellstr(lrkey_j), 'MATLAB:table:join:KeyVarNonStringError', getVarOrRowLabelsName(a,leftKeys(j)), getVarOrRowLabelsName(b,rightKeys(j)));
                % make lrkey_j_copy homogeneous
                lrkey_j_copy = lrkey_j;
                if coder.ignoreConst(false) && (coder.internal.isConst(size(lrkey_j_copy)) && ~isempty(lrkey_j_copy))
                    lrkey_j_copy{coder.ignoreConst(1)}; %#ok<VUNUS>
                end
                [~,~,lrkeys(:,j)] = matlab.internal.coder.datatypes.cellstr_unique(lrkey_j_copy);
                areMissing = ismissing(lrkey_j_copy);
            end
        end


        % To retain the correct sorting behavior for missing types, we
        % must insert NaNs into lrkeys where they are present in
        % lrkey_j. Otherwise, NaNs and other missing types will be
        % sorted as if they are finite numerical values.
        %
        % We do not skip this step for cellstr or char variables because 
        % join sorts them as if they were missing.
        if iscolumn(lrkey_j)
            lrkeys(areMissing,j) = NaN;
        elseif size(lrkey_j,2)>1
            % For multi-column variables, only insert a NaN into
            % lrkeys when the entire row is missing.
            lrkeys(all(areMissing,2)) = NaN;
            % else
            % For vars with no columns, prevent all from saying that
            % the entire row is missing
        end
    end

    if nkeys > 1
        [~,~,lrkeys2] = unique(lrkeys,'rows');
    else
        lrkeys2 = lrkeys;
    end
    leftKeyVals = lrkeys2(1:leftlen,1); % force these to be columns
    rightKeyVals = lrkeys2(leftlen+(1:rightlen),1);
end

%-----------------------------------------------------------------------
function tf = isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
tf = isequal(leftKeys,rightKeys,0) && type == "simple" ...
    && a.rowDim.requireUniqueLabels && b.rowDim.requireUniqueLabels;

%-----------------------------------------------------------------------
function vars = validateDataVars(t,varsIn)
coder.extrinsic('matches', 'unique');

rowDimName = t.metaDim.labels{1};
defaultRowDimName = t.defaultDimNames{1};

if matlab.internal.coder.datatypes.isText(varsIn)
    % Helpful error if row labels are not allowed in this context.
    t.throwSubclassSpecificErrorIf(coder.const(matches(rowDimName,varsIn)),'join:RowLabelsCannotBeDataVar');

    % Helpful error if the var name is the default 'Row'/'Time' but the table's/timetable's
    % row labels has been renamed to something else
    t.throwSubclassSpecificErrorIf(~coder.const(matches(defaultRowDimName,t.varDim.labels)) && coder.const(matches(defaultRowDimName,varsIn)),'join:RowLabelsCannotBeDataVarNondefaultName',defaultRowDimName,rowDimName);
end

vars = coder.const(t.varDim.subs2inds(varsIn));
coder.internal.errorIf(length(coder.const(unique(vars))) < length(vars),'MATLAB:table:join:DuplicateVars');

%-----------------------------------------------------------------------
function name = getVarOrRowLabelsName(t,index)
if index == 0
    name = t.metaDim.labels{1};
else
    name = t.varDim.labels{index};
end

%-----------------------------------------------------------------------
function names = getVarOrRowLabelsNames(t,indices)
isRowLabels = (indices == 0);
names = subsasgnParens({},isRowLabels,{t.metaDim.labels{1}});
names = subsasgnParens(names,~isRowLabels,subsrefParens(t.varDim.labels,indices(~isRowLabels)));

%-----------------------------------------------------------------------
function C = subsasgnParens(A,idx,B)
coder.extrinsic('subsasgn', 'substruct');
C = coder.const(subsasgn(A,substruct('()',{idx}),B));

%-----------------------------------------------------------------------
function C = subsrefParens(A,idx)
coder.extrinsic('subsref', 'substruct');
C = coder.const(subsref(A,substruct('()',{idx})));
