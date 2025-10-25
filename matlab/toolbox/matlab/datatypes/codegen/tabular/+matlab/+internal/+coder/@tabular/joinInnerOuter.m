function [c,il,ir] = joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyVals,rightKeyVals, ...
    leftVars,rightVars,leftKeys,rightKeys,leftVarDim,rightVarDim, ...
    mergeKeyProps,c_metaDim) %#codegen
%JOININNEROUTER Common calculations for innerJoin and outerJoin.

% C is [A(IA,LEFTVARS) B(IB,RIGHTVARS)], where IA and IB are row indices into A
% and B computed for each row of C from LEFTKEYVALS and RIGHTKEYVALS.  These
% index vectors may include zeros indicating "no source row in A/B)" for some
% rows of C.

%   Copyright 2012-2021 The MathWorks, Inc.

% Sort each key.
[lkeySorted,lkeySortOrd] = sort(leftKeyVals);
[rkeySorted,rkeySortOrd] = sort(rightKeyVals);

% Get unique key values and counts. This also gives the beginning and end of
% each block of constant key values in each. All of these end up 0x1 if the
% corresponding key is empty.
lbreaks = find(diff(lkeySorted)); % breakpoints from one key value to the next
rbreaks = find(diff(rkeySorted));
lones = ones(~isempty(leftKeyVals),1); % scalar 1, or empty 0x1
rones = ones(~isempty(rightKeyVals),1);
lstart = [lones; lbreaks+1]; % start of each block of constant key values
rstart = [rones; rbreaks+1];
lend = [lbreaks; length(lkeySorted)*lones]; % end of each block of constant key values
rend = [rbreaks; length(rkeySorted)*rones];
lunique = lkeySorted(lstart); % unique key values
runique = rkeySorted(rstart);
luniqueCnt = lend - lstart + 1; % number of unique key values
runiqueCnt = rend - rstart + 1;

% Use the "block nested loops" algorithm to determine how many times to
% replicate each row of A and B.  Rows within each "constant" block of keys in
% A will need to be replicated as many times as there are rows in the matching
% block of B, and vice versa.  Rows of A that don't match anything in B, or
% vice versa, get zero.  Rows of A will be replicated row-by-row; rows in B
% will be replicated block-by-block.
il1 = 1;
ir1 = 1;
leftElemReps = zeros(size(lunique));
rightBlockReps = zeros(size(runique));
while (il1 <= length(lunique)) && (ir1 <= length(runique))
    if lunique(il1) < runique(ir1)
        il1 = il1 + 1;
    elseif lunique(il1) == runique(ir1)
        leftElemReps(il1) = runiqueCnt(ir1);
        rightBlockReps(ir1) = luniqueCnt(il1);
        il1 = il1 + 1;
        ir1 = ir1 + 1;
    elseif lunique(il1) > runique(ir1)
        ir1 = ir1 + 1;
    else % one must have been NaN
        % NaNs get sorted to end; nothing else will match
        break;
    end
end

% Identify the rows of A required for an inner join: expand out the number of
% replicates within each block to match against the (non-unique) sorted keys,
% then replicate each row index the required number of times.
leftElemReps = repelem(leftElemReps,luniqueCnt);
il1 = repelem(1:length(lkeySorted),leftElemReps)';

% Identify the rows of B required for an inner join: replicate the start and
% end indices of each block of keys the required number of times, then create
% a concatenation of those start:end expressions.
rstart = repelem(rstart,rightBlockReps);
rend = repelem(rend,rightBlockReps);
% Special cases are needed when rstart &/or rend is scalar, as otherwise
% coloncat will fail if rstart or rend is assumed non-scalar at
% compile-time, but is scalar at runtime.
if isscalar(rstart) && isscalar(rend)
    ir1 = matlab.internal.datatypes.coloncat(rstart(1),rend(1))';
elseif isscalar(rstart) && ~isscalar(rend)
    ir1 = matlab.internal.datatypes.coloncat(rstart(1),rend)';
elseif ~isscalar(rstart) && isscalar(rend)
    ir1 = matlab.internal.datatypes.coloncat(rstart,rend(1))';
else
    ir1 = matlab.internal.datatypes.coloncat(rstart,rend)';
end

% Translate back to the unsorted row indices.
if coder.internal.isConstFalse(isempty(lkeySortOrd)) || coder.internal.isConstFalse(isempty(il1))
    il1 = lkeySortOrd(il1);
end
if coder.internal.isConstFalse(isempty(rkeySortOrd)) || coder.internal.isConstFalse(isempty(ir1))
    ir1 = rkeySortOrd(ir1);
end

% If this is a left- or full-outer join, add the indices of the rows of A that
% didn't match anything in B.  Add in zeros for the corresponding B indices.
if leftOuter
    left = find(leftElemReps(:) == 0); % force a column for one unique left key
    il1 = [il1; lkeySortOrd(left(:))];
    ir2 = [ir1; zeros(size(left(:)))];
else
    ir2 = ir1;
end

% If this is a right- or full-outer join, add the indices of the rows of B that
% didn't match anything in A.  Add in zeros for the corresponding A indices.
if rightOuter
    rightBlockReps = repelem(rightBlockReps,runiqueCnt);
    right = find(rightBlockReps(:) == 0); % force a column for one unique right key
    il = [il1; zeros(size(right(:)))];
    ir = [ir2; rkeySortOrd(right(:))];
else
    il = il1;
    ir = ir2;
end

% Now sort the whole thing by the key.  If this is an inner join, that's
% already done.
if leftOuter || rightOuter
    pos = (il > 0);
    Key = zeros(size(il));
    Key(pos) = leftKeyVals(il(pos)); % Rows that have an A key value
    Key(~pos) = rightKeyVals(ir(~pos)); % Rows with no A key value must have a B key
    [~,ord] = sort(Key);
    if ~isempty(il)
        il = il(ord);
    end
    if ~isempty(ir)
        ir = ir(ord);
    end
end

% Compute logical indices of where A'a and B's rows will go in C,
% and the indices of which rows to pick out of A and B.
ilDest = (il > 0); ilSrc = il(ilDest);
irDest = (ir > 0); irSrc = ir(irDest);

% Create a new empty time/table based on the left input, the specified variables
% from A and from B will be added to that. Don't copy any per-array properties.
% If duplicate row labels are allowed in the output, replicate/thin from the
% left and possibly merge from the right. If row labels are required to be
% unique, only create row labels if they won't need to be replicated, otherwise
% it's too expensive to create unique row labels.
c = a.cloneAsEmpty(); % respect the subclass
c.arrayProps = tabular.mergeArrayProps(a.arrayProps,b.arrayProps); % copy over first non-empty table-wide properties
c.metaDim = c_metaDim; % use the supplied metaDim
c_rowDimTmp = a.rowDim.lengthenTo(length(il));
if a.rowDim.hasLabels
    if a.rowDim.requireUniqueLabels
        assert(b.rowDim.requireUniqueLabels) % joinUtil should prevent table/timetable joins
        if any(rightKeys == 0)
            % Preallocate output row labels to account for right-only rows
            if c_rowDimTmp.hasLabels
                labels = c_rowDimTmp.labels;
            else
                labels = c_rowDimTmp.defaultLabels();
            end
            % Always copy left row labels to output, even if not a key
            if iscell(labels)
                a_rowDim_labels = a.rowDim.labels;
                if ~coder.internal.isConst(sum(ilDest))
                    % Ensure a_rowDim_labels is homogeneous
                    coder.varsize('a_rowDim_labels',[],[0 0]);
                end
                idx = 1;
                for i = 1:length(ilDest)
                    if ilDest(i)
                        labels{i} = a_rowDim_labels{ilSrc(idx)};
                        idx = idx + 1;
                    end
                end
            else
                labels(ilDest) = a.rowDim.labels(ilSrc);
            end
            if rightOuter
                if any(leftKeys == 0)
                    % Merge right row labels into output when left row labels are a key
                    if iscell(labels)
                        b_rowDim_labels = b.rowDim.labels;
                        if ~coder.internal.isConst(sum(irDest))
                            % Ensure b_rowDim_labels is homogeneous
                            coder.varsize('b_rowDim_labels',[],[0 0]);
                        end
                        idx = 1;
                        for i = 1:length(irDest)
                            if irDest(i)
                                labels{i} = b_rowDim_labels{irSrc(idx)};
                                idx = idx + 1;
                            end
                        end
                    else
                        labels(irDest) = b.rowDim.labels(irSrc);
                    end
                else
                    % Otherwise leave output row labels for right-only rows as default values.
                    % The right row labels will be merged into the key var in the output.
                end
            end
            c_rowDim = c_rowDimTmp.createLike(length(il),labels);
        else
            % In a table/table join, the right row labels must be a key if the left row
            % labels are. This avoids some situations where the row labels would have to
            % be replicated in the output, but can't be without an expensive deduplication.
            coder.internal.errorIf(any(leftKeys == 0),'MATLAB:table:join:TableRowLabelsVarKeyPairNotSupported');
            % Don't copy row labels in a table/table join if neither input's row labels are
            % a key. This avoids having to replicate them in the output.
            c_rowDim = c_rowDimTmp.createLike(length(il),{});
        end
    else
        % Preallocate output row labels to account for right-only rows. We
        % always want to create default labels as the output rowDim will
        % always be an explicit rowTimesDim.
        labels = c_rowDimTmp.defaultLabels();
        % Always copy left row labels to output, even if not a key
        if iscell(labels)
            idx = 1;
            for i = 1:length(ilDest)
                if ilDest(i)
                    labels{i} = a.rowDim.labels{ilSrc(idx)};
                    idx = idx + 1;
                end
            end
        else
            labels(ilDest) = a.rowDim.labels(ilSrc);
        end
        if rightOuter
            if any(leftKeys == 0)
                % Merge right key values into output row labels when left row labels are a key
                rightMergedKey = rightKeys(find(leftKeys == 0,1,'last'));
                rightVals = b.getVarOrRowLabelData(rightMergedKey); rightVals = rightVals{1};
                if iscell(labels)
                    idx = 1;
                    for i = 1:length(irDest)
                        if irDest(i)
                            labels{i} = rightVals{irSrc(idx)};
                            idx = idx + 1;
                        end
                    end
                else
                    labels(irDest) = rightVals(irSrc);
                end
            else
                % Otherwise leave output row labels for right-only rows as default values
            end
        end

        % When both inputs are timetables, we force the output to have
        % explicit row times.
        c_rowDim = matlab.internal.coder.tabular.private.explicitRowTimesDim(length(il),labels);

    end
else
    c_rowDim = c_rowDimTmp.createLike(length(il),{});
end
c.rowDim = c_rowDim;


% Assign var labels and merge a's and b's per-var properties.
numLeftVars = length(leftVars);
numRightVars = length(rightVars);
c_varDimTmp = leftVarDim.lengthenTo(numLeftVars+numRightVars,rightVarDim.labels);
c_varDim = c_varDimTmp.moveProps(rightVarDim,1:numRightVars,numLeftVars+(1:numRightVars));

% Fill empty leftkey variable properties with properties from the right.
% mergeKeyProps is true when neither LeftVariables nor RightVariables are
% provided, but only when MergeKeys is also true for outerjoin.
if mergeKeyProps
    i = (leftKeys > 0) & (rightKeys > 0); % exclude row label keys
    c.varDim = c_varDim.fillEmptyProps(b.varDim,rightKeys(i),leftKeys(i));
else
    c.varDim = c_varDim;
end

% Move data from A and B into C.
a_data = a.data;
c_data = coder.nullcopy(cell(1,numLeftVars+numRightVars));
c_nrows = c.rowDim.length;
for j = 1:numLeftVars
    aVarRows = matlab.internal.coder.tabular.selectRows(a_data{leftVars(j)},ilSrc);
    c_data{j} = matlab.internal.coder.tabular.broadcastRows(aVarRows,c_nrows,ilDest);
end
b_data = b.data;
for j = 1:numRightVars
    bVarRows = matlab.internal.coder.tabular.selectRows(b_data{rightVars(j)},irSrc);
    c_data{j+numLeftVars} = matlab.internal.coder.tabular.broadcastRows(bVarRows,c_nrows,irDest);
end
c.data = c_data;
