function [ainds,binds] = table2midx(a,b)
%

% TABLE2MIDX Create multi-index matrices from time/table variables for use by the
% tabular set membership methods

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.matricize

try
    paired = (nargin == 2);
    if paired
        if ~isequal(class(a),class(b))
            error(message('MATLAB:table:setmembership:TypeMismatch'));
        end
        [tf,b2a] = ismember(b.varDim.labels,a.varDim.labels);
        if ~all(tf) || (length(tf) ~= a.varDim.length)
            error(message('MATLAB:table:setmembership:DisjointVars'));
        end
        assert(a.rowDim.requireUniqueLabels == b.rowDim.requireUniqueLabels) % catch mixed tabular requirements
    end
    
    % Include all variables for row comparisons, but include row labels only if they
    % (or at least one set for paired) are not required to be unique
    nvars = a.varDim.length; % == b.varDim.length for paired
    avarIndices = 1:a.varDim.length;
    includeRowLabels = ~a.rowDim.requireUniqueLabels;
    if includeRowLabels
        nvars = nvars + 1;
        avarIndices = [0 avarIndices];
    end
    a_data = a.data;
    anrows = a.rowDim.length;
    ainds = zeros(anrows,nvars);
    if paired
        bvarIndices(1,b2a) = 1:b.varDim.length;
        if includeRowLabels
            bvarIndices = [0 bvarIndices];
        end
        b_data = b.data;
        bnrows = b.rowDim.length;
        binds = zeros(bnrows,nvars);
    end
    
    % Compute a group index vector for each var (or each pair of vars for paired)
    for j = 1:nvars
        aindex_j = avarIndices(j);
        if aindex_j == 0
            avar_j = a.rowDim.labels;
            name_j = a.metaDim.labels{1};
        else
            avar_j = matricize(a_data{aindex_j});
            name_j = a.varDim.labels{aindex_j};
        end
        if paired
            bindex_j = bvarIndices(j);
            if bindex_j == 0
                bvar_j = b.rowDim.labels;
            else
                bvar_j = matricize(b_data{bindex_j});
            end
            try
                % Call union function/method first to enforce rules about mixed types
                % that vertcat is not strict about, e.g. single and int32
                union(avar_j([],:),bvar_j([],:));
                var_j = [avar_j; bvar_j];
            catch ME
                throw(addCause(MException(message('MATLAB:table:setmembership:VarVertcatMethodFailed',name_j)), ME));
            end
        else
            var_j = matricize(avar_j);
        end
        
        % unique won't work right on multi-column cellstrs catch these here to avoid
        % the 'rows' warning which would be followed by an error
        if iscell(var_j) && ~iscolumn(var_j)
            error(message('MATLAB:table:VarUniqueMethodFailedCellRows',name_j));
        end
        
        try
            % Use 'rows' for this variable's unique method if the var is
            % not a single column. Multi-column cellstrs already weeded out.
            %
            % For categorical variables, the indices created here _will_ account for
            % categories that are not actually present in the data -- the indices
            % should not be assumed to be contiguous.
            if iscolumn(var_j)
                [~,~,inds_j] = unique(var_j,'sorted');
            else
                [~,~,inds_j] = unique(var_j,'sorted','rows');
            end
        catch ME
            throw(addCause(MException(message('MATLAB:table:VarUniqueMethodFailed',name_j)), ME));
            
        end
        if length(inds_j) ~= size(var_j,1)
            error(message('MATLAB:table:VarUniqueMethodFailedNumRows',name_j));
        end
        
        % To retain the correct sorting behavior for missing types, insert
        % missings into inds_j, where they are present in var_j. Otherwise,
        % NaNs and other missing types will be sorted by the tabular set
        % functions, as if they are normal numerical values.
        %
        % Skip this step for cellstr variables, because missing cellstr
        % values are not sorted the same as NaNs.
        
        try
            if ~iscellstr(var_j) && ~ischar(var_j) %#ok<ISCLSTR>
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
        catch ME
            if ME.identifier ~= "MATLAB:ismissing:FirstInputInvalid"
                throw(ME)
            end
        end
        ainds(:,j) = inds_j(1:anrows,1);
        if paired, binds(:,j) = inds_j((anrows+1):end,1); end
    end
    
catch ME
    throwAsCaller(ME)
end
