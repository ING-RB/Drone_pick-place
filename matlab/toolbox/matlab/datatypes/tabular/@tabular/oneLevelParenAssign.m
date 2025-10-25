function t = oneLevelParenAssign(t, indices, b, creating, isInternalCall, numRows)
%

% ONELEVELPARENASSIGN Handles one level deep assignment into a table using
% parentheses. 

% Copyright 2021-2024 The MathWorks, Inc.

% Syntax: t(rowIndices, varIndices) = b

import matlab.internal.datatypes.matricize
import matlab.internal.datatypes.isColon
import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

% Internal methods can directly pass a RHS that has the same structure as the
% internal table data representation, by specifying the isInternalCall flag as
% true. The caller is responsible for ensuring that RHS has the correct
% structure. When the RHS has zero variables but non-zero number of rows, the
% tabular data would be a 1x0 cell array, so we cannot get the number of rows
% from that. Hence, we require the to caller to provide the number of rows
% explicitly.
if nargin < 5, isInternalCall = false; end

t_nrowsExisting = t.rowDim.length;
t_nvarsExisting = t.varDim.length;
assigningInto0x0 = (t_nrowsExisting+t_nvarsExisting == 0); % all(size(t) == 0)
creatingOrAssigningInto0x0 = (creating || assigningInto0x0);
isTabularRHS = isa(b,'tabular');
if isInternalCall
    % b will have the same structure as table's internal data representation, so
    % the length of b gives us the number of variables. The number of rows is
    % provided by the caller.
    b_nvars = length(b);
    b_nrows = numRows;
elseif isTabularRHS
    b_nrows = b.rowDim.length;
    b_nvars = b.varDim.length;
else % RHS is a cell array
    [b_nrows,b_nvars] = size(b);
end

if creatingOrAssigningInto0x0
    % First sort out the row subscript, and copy the RHS's row labels
    % as appropriate
    if isColon(indices{1}) % t(:,...) = b
        % When creating a new tabular, or growing from 0x0, interpret a ':' rows
        % subscript with respect to the RHS, not as nothing.
        rowIndices = 1:b_nrows;
        numRowIndices = b_nrows;
        maxRowIndex = b_nrows;
        isColonRows = true;
        if creating || (isTabularRHS && isa(b,class(t)))
            % In either case, if the RHS is tabular, copy the rows dim,
            % including size and labels (if any), to the LHS. For creation, the
            % RHS _is_ tabular, and the LHS is assumed to be an empty tabular
            % "like" the RHS. For growing a 0x0, it must be the same "kind" of
            % tabular as the LHS.
            t.rowDim = b.rowDim;
        else
            % Otherwise the RHS is a cell array (assigning into a 0x0 tabular
            % using cell convenience syntax). Use default (possibly none) row
            % labels for the LHS.
            t.rowDim = t.rowDim.createLike(b_nrows);
        end
    else  % t(indices,...) = b, t(logical,...) = b, or t(labels,...) = b
        % Translate row labels into indices (leave logical alone).
        [rowIndices,numRowIndices,maxRowIndex,isColonRows,isRowLabels,t.rowDim] = ...
            t.subs2inds(indices{1},'rowDim', matlab.internal.tabular.private.tabularDimension.subsType_assignment);
        
        % Creating using numeric or logical subscripts copies row labels from
        % the RHS if the RHS is tabular and has row labels (the LHS is assumed
        % to be an empty tabular "like" the RHS in the creation case). Growing
        % from a 0x0 with explicit row subscripts on the LHS does not copy row
        % labels.
        if creating && ~isRowLabels && isTabularRHS && b.rowDim.hasLabels
            % Let standard assignment behavior handle repeated LHS subs.
            newLabels = b.rowDim.labels([]); newLabels(rowIndices) = b.rowDim.labels;
            % The rows being created may be discontiguous, fill in default row labels.
            holes = true(1,t.rowDim.length); holes(rowIndices) = false;
            if any(holes)
                newLabels(holes) = b.rowDim.defaultLabels(find(holes));
            end
            t.rowDim = t.rowDim.setLabels(newLabels);
        end
    end
    
    % Next sort out the vars subscript, and copy the RHS's var names and per-var
    % metadata as appropriate
    if isColon(indices{2}) % t(...,:) = b
        % When creating a new tabular, or growing from 0x0, interpret a ':' vars
        % subscript with respect to the RHS, not as nothing.
        varIndices = 1:b_nvars;
        numVarIndices = b_nvars;
        if creating || isTabularRHS
            % In either case, if the RHS is tabular, copy the rows dim,
            % including size, names, and ALL per-var metadata, to the LHS. For
            % creation, the RHS _is_ tabular, and the LHS is assumed to be an
            % empty tabular "like" the RHS. For growing a 0x0, it may or may not
            % be tabular.
            t.varDim = b.varDim;
        else
            % Otherwise the RHS is a cell array (assigning into a 0x0 tabular
            % using cell convenience syntax). Use default (possibly none) var
            % names for the LHS, and there's no metadata to copy.
            t.varDim = t.varDim.createLike(b_nvars,t.varDim.defaultLabels(1:b_nvars));
        end
    else  % t(...,indices) = b, t(...,logical) = b, or t(...,labels) = b
        % Translate variable names or logical into indices.
        [varIndices,numVarIndices,~,~,isVarNames,t.varDim] = ...
            t.subs2inds(indices{2},'varDim',matlab.internal.tabular.private.tabularDimension.subsType_assignment);
        
        % Creating using numeric or logical subscripts copies var names from the
        % RHS if that is tabular. The LHS is assumed to be an empty tabular
        % "like" the RHS.
        if creating && ~isVarNames && isTabularRHS
            % Let standard assignment behavior handle repeated LHS subs.
            newLabels = {}; newLabels(varIndices) = b.varDim.labels;
            % Scalar expansion can result in duplicate variable names, so fix
            % the newLabels before assignment.
            if (b_nrows*b_nvars == 1) % isscalar(b)
                newLabels = matlab.lang.makeUniqueStrings(newLabels,{},namelengthmax);
            end
            t.varDim = t.varDim.setLabels(newLabels);
        end
    end
    
    % Creating a tabular will take per-array metadata and dimension metadata
    % from the RHS if that is tabular.
    if creating && isTabularRHS
        t.arrayProps = b.arrayProps;
        t.metaDim = t.metaDim.setLabels(b.metaDim.labels);
    end
    
else
    % Assignment into an existing non-degenerate table
    subsType = matlab.internal.tabular.private.tabularDimension.subsType_assignment;
    
    % Translate row labels into indices (leave logical and ':' alone), and
    % update the rowDim.
    [rowIndices,numRowIndices,maxRowIndex,isColonRows,~,t.rowDim] = ...
        t.subs2inds(indices{1},'rowDim',subsType);
    % Translate variable names, logical, or ':' into indices and update the
    % varDim.
    [varIndices,numVarIndices,~,~,~,t.varDim] = ...
        t.subs2inds(indices{2},'varDim',subsType);
end

% Assignment from a table.  This operation is supposed to replace or
% grow at the level of the _table_.  So no internal reshaping of
% variables is allowed -- we strictly enforce sizes. In other words, the
% existing table has a specific size/shape for each variable, and
% assignment at this level must respect that.

if b_nrows*b_nvars == 1 % isscalar(b)
    % If it is not an internal call, then the RHS is a single table element
    % or a cell (it may itself contain a non-scalar), scalar expand it to
    % the size of the target LHS subarray. In case of internal calls, let
    % the assignment below handle scalar expansion for existing variables.
    % For new variables we would do the scalar expansion later on, if
    % required. For internal calls, the caller would have already verified
    % the sizes of the LHS, so do not worry about unintended scalar
    % expansion.
    if ~isInternalCall % RHS is a cell or table
        b = repmat(b,numRowIndices,numVarIndices);
        [b_nrows,b_nvars] = size(b); % keep these current
    end
else
    % Tabular assignment requires equal RHS and LHS sizes even for
    % empty-to-empty assignment. This is stricter than the core types, but
    % their behavior for empty assignments is only there for legacy reasons.
    % Per-var properties make tabular assignment more complex than numeric.
    if b_nrows ~= numRowIndices
        error(message('MATLAB:table:RowDimensionMismatch'));
    elseif b_nvars ~= numVarIndices
        error(message('MATLAB:table:VarDimensionMismatch'));
    end
end

if isInternalCall
    b_data = b;
elseif isTabularRHS
    b_data = b.data;
elseif iscell(b) 
    if ~ismatrix(b)
        error(message('MATLAB:table:NDCell'));
    end
    b_data = tabular.container2vars(b);
else
    % Raw values are not accepted as the RHS with '()' subscripting:  With a
    % single variable, you can use dot subscripting.  With multiple variables,
    % you can either wrap them up in a table, accepted above, or use braces
    % if the variables are homogeneous.
    error(message('MATLAB:table:InvalidRHS'));
end

% varIndices might contain repeated indices into t, but existingVarLocsInB and
% newVarLocsInB (see below) always contain unique (and disjoint) indices into b.
% In that case multiple vars in b will overwrite the same var in t, last one wins.
existingVars = (varIndices <= t_nvarsExisting); % t's original number of vars
existingVarLocsInB = find(existingVars); % vars in b being assigned to existing vars in t
t_data = t.data; t.data = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
for j = existingVarLocsInB
    var_j = t_data{varIndices(j)}; t_data{varIndices(j)} = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
    % The size of the RHS has to match what it's going into.
    try
        if isInternalCall && (b_nrows*b_nvars == 1)
            var_b = b_data{1};
        else
            var_b = b_data{j};
        end
            
        if ~ismatrix(var_b)            
            var_b = matricize(var_b);
        end

        % Save attributes of var_j for error handling before attempting assignment in-place (which renders var_j inaccessible after exception)
        sizeLHS = size(var_j); sizeLHS(1) = numRowIndices;
        var_j_ischar = ischar(var_j);

        % In cases where the whole var is moved, i.e. rowIndices is ':', this is faster, but a valid
        % RHS may not have same type or trailing size as the LHS var, and it's difficult to do the
        % right error checking - so do it as a subscripted assignment.
        % if isColonRows && isequal(sizeLHS,size(b_data{j}))) && isa(b_data{j},class(var_j))
        %     var_j = var_b;
        % else
        if isa(var_j,'tabular')
            % Since we are in a try-catch block, need to put the assignment
            % expression in a local function to avoid shared data copy.
            % Since we already know we are doing one level of paren
            % assignment, directly call oneLevelParenAssign.
            var_j = move(var_j).oneLevelParenAssign({rowIndices ':'}, var_b, creating);
        else
            var_j(rowIndices,:) = var_b;
        end
        % end
        % No need to check for size change, RHS and LHS are identical sizes.
        t_data{varIndices(j)} = var_j;
    catch ME
        if matches(ME.identifier, ["MATLAB:invalidConversion" "MATLAB:UnableToConvert"])
            if iscell(b) && var_j_ischar && iscellstr(var_b) %#ok<ISCLSTR>
                % Give a specific error when tabular.container2vars has converted
                % char inside a cell RHS into a cellstr.
                error(message('MATLAB:table:CharAssignFromCellRHS'));
            else
                % Otherwise preserve the conversion error.
                rethrow(ME);
            end
        elseif prod(sizeLHS) ~= prod(size(b_data{j})) %#ok<PSIZE> avoid numel, it may return 1
            % Already checked that the height of the RHS is the same as the
            % number of LHS rows being assigned into. But for each variable,
            % the "internal" sizes must match.
            sizeLHS = strjoin(string(sizeLHS), '-by-');
            sizeRHS = strjoin(string(size(b_data{j})), '-by-');
                error(message('MATLAB:table:AssignmentDimensionMismatch', t.varDim.labels{varIndices(j)}, sizeLHS, sizeRHS));
        elseif (ME.identifier == "MATLAB:subsassigndimmismatch") ...
                && var_j_ischar && isstring(var_b)
            % String into Nx1 char is a special case: the string elements
            % are converted to char row vectors, and may not be the correct
            % strlength to assign into the LHS char. But the check against
            % sizeLHS fails to catch the "inner" size mismatch because the
            % RHS has the right "outer" size before conversion to char.
            sizeLHS = strjoin(string(sizeLHS), '-by-');
            sizeRHS = strjoin(string(size(b_data{j})), '-by-');
                error(message('MATLAB:table:AssignmentDimensionMismatch', t.varDim.labels{varIndices(j)}, sizeLHS, sizeRHS));               
        else
            rethrow(ME);
        end
    end
end

% Add new variables if necessary.  Note that b's varnames do not
% propagate to a in () assignment, unless t is being created or grown
% from 0x0.  They do for horzcat, though.
newVarLocsInB = find(~existingVars); % vars in b being assigned to new vars in t
newVarLocsInT = varIndices(~existingVars); % new vars being created in t (possibly repeats)
if ~isempty(newVarLocsInB)
    % Warn if we have to lengthen the new variables to match the height of
    % the table. Don't warn about default values "filled in in the middle"
    % for these new vars.
    if maxRowIndex < t_nrowsExisting
        warning(message('MATLAB:table:RowsAddedNewVars'));
    end
    
    % Add cells for new vars being created, not including repeated LHS var subscripts.
    numUniqueNewVarsAssignedTo = length(unique(newVarLocsInT));
    t_data = [t_data cell(1,numUniqueNewVarsAssignedTo)];

    if isInternalCall && (b_nrows*b_nvars == 1)
        % Do the scalar expansion for internal calls before assignment. We
        % already know the number of rows we need. The number of columns for
        % new variables is set to 1 when assigning a scalar value. The sizes
        % along other dimensions should match the other existing variables
        % in the assignment. If we are only creating new variables, then
        % those variables would be nrowsx1 vectors.
        if ~isempty(existingVarLocsInB)
            sz = size(t_data{varIndices(existingVarLocsInB(1))});
            sz = [numRowIndices 1 sz(3:end)];
        else
            sz = [numRowIndices 1];
        end
        b_data{1} = repmat(b_data{1},sz);
    end
    
    for j = newVarLocsInB

        if isInternalCall && (b_nrows*b_nvars == 1)
            var_b = b_data{1};
        else
            var_b = b_data{j};
        end
            
        if isColonRows
            var_j = var_b;
        else
            % Start the new variable out as 0-by-(trailing size of b),
            % then let the assignment add rows.
            var_j = repmat(var_b,[0 ones(1,ndims(var_b)-1)]);
            if isa(var_b,'tabular')
                % Since we are in a try-catch block, need to put the assignment
                % expression in a local function to avoid shared data copy.
                % Since we already know we are doing one level of paren
                % assignment, directly call oneLevelParenAssign.
                var_j = move(var_j).oneLevelParenAssign({rowIndices ':'}, matricize(var_b), creating);
            else
                var_j(rowIndices,:) = matricize(var_b);
            end
        end
        % A new var may need to grow to fit the table
        if size(var_j,1) < t_nrowsExisting % t's original number of rows
            var_j = matlab.internal.datatypes.lengthenVar(var_j, t_nrowsExisting);
        end
        t_data{varIndices(j)} = var_j;
    end
    
    % Copy per-var properties from b to t.
    if isTabularRHS
        t.varDim = t.varDim.moveProps(b.varDim,newVarLocsInB,newVarLocsInT);
    end
    % Detect conflicts between the new var names and the existing dim names.
    t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
end
t.data = t_data;

if (maxRowIndex > t_nrowsExisting) % t's original number of rows
    % If the vars being assigned to are now taller than the table, add rows
    % to the rest of the table, including row labels.  This might be because
    % the assignment lengthened existing vars, or because the assignment
    % created new vars taller than the table.  Warn only if we have to
    % lengthen existing vars that have not been assigned to -- if there's
    % currently only one var in the table (which might be existing or new),
    % don't warn about any default values "filled in in the middle".
    numUniqueExistingVarsAssignedTo = length(unique(varIndices(existingVars)));
    if numUniqueExistingVarsAssignedTo < t_nvarsExisting % some existing vars were not assigned to
        warning(message('MATLAB:table:RowsAddedExistingVars'));
    end
    % update nrows
    for j = 1:t.varDim.length
        if size(t.data{j},1) < maxRowIndex
            t.data{j} = matlab.internal.datatypes.lengthenVar(t.data{j}, maxRowIndex);
        end
    end
end
