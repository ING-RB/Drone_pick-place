function [ainds,binds] = table2midx(a,b) %#codegen
% TABLE2MIDX Create multi-index matrices from time/table variables for use by the
% tabular set membership methods

%   Copyright 2019 The MathWorks, Inc.

    paired = (nargin == 2);
    if paired
        coder.internal.assert(isequal(class(a),class(b)),'MATLAB:table:setmembership:TypeMismatch');
        coder.internal.assert(b.varDim.length == a.varDim.length, 'MATLAB:table:setmembership:DisjointVars');
        coder.internal.assert(all(strcmp(b.varDim.labels,a.varDim.labels)), 'MATLAB:table:setmembership:DisjointVars');
        coder.internal.assert(a.rowDim.requireUniqueLabels == b.rowDim.requireUniqueLabels, 'MATLAB:assertion:failed'); % catch mixed tabular requirements
    end
    
    % Include all variables for row comparisons, but include row labels only if they
    % (or at least one set for paired) are not required to be unique
    nvars = a.varDim.length; % == b.varDim.length for paired
    includeRowLabels = ~a.rowDim.requireUniqueLabels;
    if includeRowLabels
        nvars = nvars + 1;
        varIndices = [0 1:a.varDim.length];
    else
        varIndices = 1:a.varDim.length;
    end
    a_data = a.data;
    anrows = a.rowDimLength;
    ainds = zeros(anrows,nvars);
    if paired
        b_data = b.data;
        bnrows = b.rowDimLength;
        binds = zeros(bnrows,nvars);
    end
    
    % Compute a group index vector for each var (or each pair of vars for paired)
    coder.unroll();
    for j = 1:nvars
        index_j = varIndices(j);
        if index_j == 0
            avar_j = a.rowDim.labels;
            name_j = a.metaDim.labels{1};
        else
            avar_j = matlab.internal.coder.datatypes.matricize(a_data{index_j});
            name_j = a.varDim.labels{index_j};
        end
        if paired
            if index_j == 0
                bvar_j = b.rowDim.labels;
            else
                bvar_j = matlab.internal.coder.datatypes.matricize(b_data{index_j});
            end
                if iscell(avar_j) || iscell(bvar_j)
                    % Union and vertcat do not accept cells for codegen, so need to handle that case
                    % separately
                    coder.internal.assert(iscell(avar_j) && iscell(bvar_j), 'MATLAB:table:setmembership:DisjointVars');
                    coder.internal.assert(iscolumn(avar_j) && iscolumn(bvar_j), 'MATLAB:table:VarUniqueMethodFailedCellRows', index_j);
                    a_sz = numel(avar_j);
                    b_sz = numel(bvar_j);
                    var_j = cell(a_sz + b_sz,1);
                    for k = 1:numel(var_j)
                       if k <= a_sz
                           var_j{k} = avar_j{k};
                       else
                           var_j{k} = bvar_j{k-a_sz};
                       end
                    end
                else
                    % Call union function/method first to enforce rules about mixed types
                    % that vertcat is not strict about, e.g. single and int32
                    union(avar_j([],:),bvar_j([],:),'rows','stable');
                    var_j = [avar_j; bvar_j];
                end
        else
            var_j = matlab.internal.coder.datatypes.matricize(avar_j);
        end
        
        % unique won't work right on multi-column cellstrs catch these here to avoid
        % the 'rows' warning which would be followed by an error
        coder.internal.errorIf(iscell(var_j) && ~iscolumn(var_j),'MATLAB:table:VarUniqueMethodFailedCellRows', index_j);    
        
        % Use 'rows' for this variable's unique method if the var is
        % not a single column. Multi-column cellstrs already weeded out.
        %
        % For categorical variables, the indices created here _will_ account for
        % categories that are not actually present in the data -- the indices
        % should not be assumed to be contiguous.
        if iscell(var_j)
            % unique only accepts cellstr, error if it is any other type of cell array
            coder.internal.errorIf(~iscellstr(var_j),'MATLAB:table:setmembership:VarVertcatMethodFailed', index_j);
            % We call varsize on our variable to convert a heterogeneous cellstr to a homogeneous,
            % as cellstr_unique only accepts homogeneous cellstrs. We use a temporary variable
            % cellstrvar_j to avoid enforcing the varsize restriction on other non-cellstr variables.
            cellstrvar_j = var_j;
            if coder.ignoreConst(false) && (coder.internal.isConst(size(var_j)) && ~isempty(var_j))
                cellstrvar_j{coder.ignoreConst(1)};
            end
            [~,~,inds_j] = matlab.internal.coder.datatypes.cellstr_unique(cellstrvar_j);
        elseif coder.internal.isConst(iscolumn(var_j)) && iscolumn(var_j)
            % If it can be determined at compile time that var_j is a column
            % vector, then call unique without the rows flag. Otherwise be
            % conservative and call unique with the rows flag supplied.
            [~,~,inds_j] = unique(var_j,'sorted');
        else
            [~,~,inds_j] = unique(var_j,'sorted','rows');
        end
            
        coder.internal.errorIf(length(inds_j) ~= size(var_j,1), 'MATLAB:table:VarUniqueMethodFailedNumRows', index_j);
        
        % To retain the correct sorting behavior for missing types, insert
        % missings into inds_j, where they are present in var_j. Otherwise,
        % NaNs and other missing types will be sorted by the tabular set
        % functions, as if they are normal numerical values.
        %
        % Skip this step for cellstr variables, because missing cellstr
        % values are not sorted the same as NaNs.

        if ~iscellstr(var_j) && ~ischar(var_j)
            if iscolumn(var_j)
                inds_j(ismissing(var_j)) = NaN;
            elseif size(var_j,2) > 1
                % For multi-column variables, only insert a NaN into
                % inds_j when the entire row is missing.

                if isa(var_j,'timetable')
                    % For timetables within tables, we need to also
                    % check if the RowTimes have missing values.
                    missingTimes = ismissing(var_j.Properties.RowTimes);
                    missingVar_j = ismissing(var_j);
                    inds_j(all([missingTimes,missingVar_j],2)) = NaN;
                else
                    inds_j(all(ismissing(var_j),2)) = NaN;
                end
            % else
                % For vars with no columns, prevent all from saying that
                % the entire row is missing
            end
        end

        ainds(:,j) = inds_j(1:anrows,1);
        if paired, binds(:,j) = inds_j((anrows+1):(anrows+bnrows),1); end
    end
end