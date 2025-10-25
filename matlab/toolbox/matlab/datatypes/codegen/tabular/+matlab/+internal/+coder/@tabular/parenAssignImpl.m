function t = parenAssignImpl(t,rhs,isInternalCall,numRows,varargin)  %#codegen
% PARENASSIGNIMPL Internal implementation of paren based subscripted assignment
% on tabular. 

% Copyright 2021-2022 The MathWorks, Inc.

% Internal methods can directly pass a rhs that has the same structure as the
% internal table data representation, by specifying the isInternalCall flag as
% true. Since the signature of parenAssign cannot be changed to accept an
% additional boolean flag, we use the parenAssignImpl method to do that.
% parenAssign simply calls parenAssignImpl with isInternalCall set to false.
% When the RHS has zero variables but non-zero number of rows, the tabular data
% would be a 1x0 cell array, so we cannot get the number of rows from the data.
% Hence, we require the caller to also provide the number of rows explicitly.

subsTypes = matlab.internal.coder.tabular.private.tabularDimension.subsType; % "import" for calls to subs2inds

coder.internal.errorIf(numel(varargin) == 1, 'MATLAB:table:LinearSubscript');
coder.internal.assert(numel(varargin) == t.metaDim.length, 'MATLAB:table:NDSubscript'); % Error for ND indexing

t_nvarsExisting = t.varDim.length;

isTabularRHS = isa(rhs,'matlab.internal.coder.tabular');
if isInternalCall
    % rhs will have the same structure as table's internal data representation, so
    % the length of b gives us the number of variables. The number of rows is
    % provided by the caller.
    rhs_nvars = size(rhs,2);
    rhs_nrows = numRows;
    scalarrhs = (rhs_nrows*rhs_nvars == 1);
elseif isTabularRHS
    rhs_nvars = rhs.varDim.length;
    rhs_nrows = rhs.rowDimLength();
    
    % if empty data, we know rhs is not scalar. This avoids using
    % rhs.rowDim.length (which may be unknown at compile time) to determine
    % scalarrhs
    if isempty(rhs.data)
        scalarrhs = false;
    else
        scalarrhs = (rhs_nrows*rhs_nvars == 1);
    end
else % rhs is a cell array
    [rhs_nrows,rhs_nvars] = size(rhs);
    scalarrhs = (rhs_nrows*rhs_nvars == 1);
end
% The scalar case is a special case to support scalar expansion. Only allow
% this case if the size of rhs is constant.
if ~coder.internal.isConst(scalarrhs)
    scalarrhs = false;
end

% Assignment into or deletion from an existing non-degenerate table
%if deleting
%    subsType = subsType.deletion;
%else
subsType = subsTypes.assignment;
%end

% Translate row labels into indices (leave logical and ':' alone).
[rowIndicesUnthinned,numRowIndices,~,isColonRows,isRowLabels] = ...
    t.rowDim.subs2inds(varargin{1},subsType);

% Translate variable names, logical, or ':' into indices.
[varIndices,numVarIndices] = t.varDim.subs2inds(varargin{2},subsType,t.data);

scalarrhs = coder.const(scalarrhs);
if scalarrhs % isscalar(rhs)
    % If it is not an internal call, then the RHS is a single table element
    % or a cell (it may itself contain a non-scalar), scalar expand it to
    % the size of the target LHS subarray. In case of internal calls, let
    % the assignment below handle scalar expansion for existing variables. For
    % internal calls, the caller would have already verified the sizes of the
    % LHS, so do not worry about unintended scalar expansion.
    if isInternalCall
        rhs1 = rhs;
    elseif isTabularRHS
        % tabular don't support repmat yet, scalar expand later
        rhs1 = rhs;
    else % is cell array
        % Expand the rhs to the size of the target lhs subarray.
        rhs1 = repmat(rhs,numRowIndices,numVarIndices);
        [rhs_nrows,rhs_nvars] = size(rhs1); %#ok<ASGLU> keep these current
    end
else
    % Tabular assignment requires equal RHS and LHS sizes even for
    % empty-to-empty assignment. This is stricter than the core types, but
    % their behavior for empty assignments is only there for legacy reasons.
    % Per-var properties make tabular assignment more complex than numeric.
    coder.internal.assert(rhs_nrows == numRowIndices, 'MATLAB:table:RowDimensionMismatch');
    coder.internal.assert(rhs_nvars == numVarIndices, 'MATLAB:table:VarDimensionMismatch');
    rhs1 = rhs;
end

if isInternalCall
    % Already has the correct structure.
    rhs_data = rhs1;
elseif isTabularRHS
    rawrhs_data = rhs1.data;
    if scalarrhs   % scalar expand tabular rhs now
        % Ideally what we need to do is
        % repmat({repmat(rawrhs_data{1},numRowIndices,1)},1,numVarIndices); but
        % rawrhs_data{1} could be a tabular itself and so repmat would fail. So
        % to work around that we first repmat the rawrhs_data into a
        % (numRowIndices x numVarIndices) cell array and then call
        % container2vars on it to convert it into the tabular data
        % representation.
        rhs_cell = repmat(rawrhs_data, numRowIndices, numVarIndices);
        [rhs_nrows,rhs_nvars] = size(rhs_cell); %#ok<ASGLU> keep these current
        rhs_data = tabular.container2vars(rhs_cell);
    else
        rhs_data = rawrhs_data;
    end
else
    % Raw values are not accepted as the RHS with '()' subscripting:  With a
    % single variable, you can use dot subscripting.  With multiple variables,
    % you can either wrap them up in a table, accepted above, or use braces
    % if the variables are homogeneous.
    coder.internal.assert(iscell(rhs1), 'MATLAB:table:InvalidRHS');
    coder.internal.assert(ismatrix(rhs1), 'MATLAB:table:NDCell');
    rhs_data = tabular.container2vars(rhs1);
end

% varIndices might contain repeated indices into t, but existingVarLocsInB and
% newVarLocsInB (see below) always contain unique (and disjoint) indices into b.
% In that case multiple vars in b will overwrite the same var in t, last one wins.
%existingVars = (varIndices <= t_nvarsExisting); % t's original number of vars
%existingVarLocsInB = find(existingVars); % vars in b being assigned to existing vars in t
t_data = t.data;

% codegen does not support growing by assignment. Out of range numeric/logical
% indices on the LHS of an assignment are an error in subs2inds. For tabulars that
% require unique row labels, unmatched native LHS subscripts are also an error in
% subs2inds. But for tabulars that allow row labels to be duplicates, unmatched
% native LHS subscripts get to here without error but are just ignored in assignment.
% ***This is by design, and different than MATLAB, and different than reference in
% codegen.*** Thin the LHS subscripts and decrease the count to match, but wait until
% we do the assignment to thin each RHS var.
if isRowLabels
    matchedLabels = (rowIndicesUnthinned > 0);
    rowIndices = rowIndicesUnthinned(matchedLabels);
    numRowIndices = numel(rowIndices);
    % numRowIndices might become non-const at this point, which could cause problems
    % in container2vars above, so do the assignment down here.
else
    rowIndices = rowIndicesUnthinned;
end

% For majority of the cases, t_data and rhs_data would be heterogeneous and the
% loop would unroll automatically. However, there might be cases where these
% variables might start as heterogeneous cell arrays but end up being
% homogenized and the loop would not unroll. This leads to size mismatch
% errors after the loop. To avoid these, explicitly unroll the loop if one of
% these variables is heterogeneous. This also ensures that we do not unroll the
% loop if these values were homogeneous to begin with.
coder.unroll(coder.internal.isConst(numel(varIndices)) ...
    && (~coder.internal.isHomogeneousCell(t_data) || ~coder.internal.isHomogeneousCell(rhs_data)));
for j = 1:numel(varIndices)
    if varIndices(j) <= t_nvarsExisting && (~isempty(rowIndices) || ...
            (islogical(rowIndices) && ~any(rowIndices)))
        var_j = t_data{varIndices(j)};
        sizeLHS = size(var_j); sizeLHS(1) = numRowIndices;

        % The size of the RHS has to match what it's going into.
        if scalarrhs && isInternalCall
            var_b1 = rhs_data{1};
        else
            var_b1 = rhs_data{j};
        end
        
        if ismatrix(var_b1)
            var_b2 = var_b1;
        else
            var_b2 = matlab.internal.coder.datatypes.matricize(var_b1);
        end

        if scalarrhs && isInternalCall
            % Still a scalar, will be assigned to all elements of LHS
            var_b = var_b2;
        elseif iscell(var_j) % if var_j is cell, var_b must also, otherwise compile error
            % May or may not have native row labels, and if we do, may or may not need to
            % thin the RHS cell below. But all cell cases go through here. No parens
            % support, so wait until we do the assignment loop below to thin each RHS var.
            var_b = var_b2;
        else
            if isRowLabels
                % rowIndices was thinned to remove any unmatched native labels, thin
                % the RHS var to match that.
                var_b = var_b2(matchedLabels,:);
            else
                var_b = var_b2; % don't need to thin
            end
        end
        
        % In cases where the whole var is moved, i.e. rowIndices is ':', this is faster, but a valid
        % RHS may not have same type or trailing size as the LHS var, and it's difficult to do the
        % right error checking - so do it as a subscripted assignment.
        if isa(var_j,'matlab.internal.coder.tabular')
            var_j = parenAssign(var_j,var_b,rowIndices,':'); %  % force dispatch to overloaded table subscripting
        elseif iscell(var_j)
            if islogical(rowIndices)
                numericRowIndices = find(rowIndices);
            elseif isColonRows
                numericRowIndices = 1:t.rowDimLength();
            else
                numericRowIndices = rowIndices;
            end

            if scalarrhs && isInternalCall
                % var_b is still a scalar, loop below will assign to all elements of LHS
            else
                if isRowLabels
                    % Assign only from those RHS values that correspond to LHS subscripts
                    % that matched a row label.
                    iRHS = find(matchedLabels); % rows of var_b to be assigned from
                else
                    % No thinning, assign all values from RHS to LHS.
                    iRHS = 1:numel(numericRowIndices);
                end
            end

            % For cell vars, we use explicit for loops to do the assignment, one
            % element at a time. Before doing that we need to ensure that the
            % sizes of the LHS and RHS are the same if we are not doing scalar
            % expansion. For other cases the core assignment would do the size
            % checks for us. In addition to these checks, we use 2D indexing to
            % do the assignment, so figure out the correct number of columns as
            % well for each case.
            if scalarrhs && isInternalCall
                % Since var_b would be a scalar, use the product of the
                % trailing sizes of var_j to figure out the number of columns.
                numCols = prod(sizeLHS(2:end));
            else
                % Verify sizes. sizeLHS by now reflects the thinned number of subscripts,
                % but a cell var_b hasn't been thinned, so adjust the check to use its
                % thinned height. We already know that rhs_nrows is the correct unthinned
                % height (rhs_nrows == [original]numRowIndices), so this check is really
                % only needed for the trailing sizes of var_j and rhs_data{j}.
                sizeRHS = size(rhs_data{j}); sizeRHS(1) = length(numericRowIndices);
                coder.internal.assert(isequal(sizeLHS, sizeRHS),...
                    'MATLAB:table:AssignmentDimensionMismatchCodegen',t.varDim.labels{varIndices(j)});
                % var_j could be ND var. Since var_b would have been
                % matricized, use the size of var_b to figure out the number of
                % columns for the assignment.
                numCols = size(var_b,2);
            end
            % unroll the loop as long as the number of iterations is
            % constant. This can avoid unnecessarily turning var_b1 into a
            % homogeneous cell array.
            unrollflag = coder.internal.isConst(numel(numericRowIndices));
            coder.unroll(unrollflag);
            for i = 1:numel(numericRowIndices)
                for k = 1:numCols
                    if scalarrhs && isInternalCall
                        % If it was an internal call and rhs was a scalar, then
                        % it would still be a scalar and we should assign that
                        % value to each element of the lhs.
                        var_j{numericRowIndices(i),k} = var_b{1};
                    else
                        % var_b was already a non-scalar or was scalar expanded
                        % to the correct size. Assign only those RHS values that
                        % correspond to LHS subscripts that matched a row label.
                        var_j{numericRowIndices(i),k} = var_b{iRHS(i),k};
                    end
                end
            end
            
            if ~coder.internal.isConst(numericRowIndices) && ~isempty(var_j) && ...
                    ~coder.internal.isConst(size(var_j{1})) && ...
                    coder.internal.isConst(size(t_data{varIndices(j)}{1}))
                % If the table variable has fix-sized cells but
                % var_j has variable-sized cells, var_j has most likely
                % been forced into a homogeneous cell array.
                % Check for common causes return informative error messages.
                nonconstlabels = isRowLabels && ...
                    ~coder.internal.isConst(t.rowDim.labels);
                
                % non-constant row labels
                coder.internal.errorIf(nonconstlabels, ...
                    'MATLAB:table:NonconstantCellAssignmentByRowName');
                
                % non-constant row indices
                coder.internal.errorIf(~nonconstlabels, ...
                    'MATLAB:table:NonconstantCellAssignment');
            end
        else
            var_j(rowIndices,:) = var_b;
        end
        % No need to check for size change, RHS and LHS are identical sizes.
        t_data{varIndices(j)} = var_j;
    end
end
t.data = t_data;


