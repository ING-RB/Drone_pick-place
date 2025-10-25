function t = parenDelete(t,idxOp)
%

% PARENDELETE Subscripted deletion from a table using parens.
%   T(I,J) = [] deletes entire rows or variables from the table T.  At least one
%   of I and J must be a :, since deleting a subset of a row or variable is not
%   allowed, the other one could be positive integer, vector of positive integers,
%   row/variable name, string/cell array containing one or more row/variable
%   names, or a logical vector.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

% Syntax:  t(rowIndices,:) = []
%          t(:,varIndices) = []
%          t(:,:) = [] deletes all rows, but doesn't delete any vars
%          t(rowIndices,varIndices) = [] is illegal
%
% Deletion of complete rows or entire variables. Only single-level deletion will
% dispatch to parenDelete, other cases are handled by parenAssign.

try
    if numel(idxOp(1).Indices) ~= t.metaDim.length
        tabular.throwNDSubscriptError(numel(idxOp(1).Indices))
    end
    
    t_nrowsExisting = t.rowDim.length;
    t_nvarsExisting = t.varDim.length;
    % Deletion from an existing non-degenerate table
    subsType = matlab.internal.tabular.private.tabularDimension.subsType_deletion;
    
    % Translate row labels into indices (leave logical and ':' alone), and
    % update the rowDim.
    [rowIndices,numRowIndices,~,isColonRows,~,t.rowDim] = ...
        t.subs2inds(idxOp(1).Indices{1},'rowDim',subsType);
    % Translate variable names, logical, or ':' into indices and update the
    % varDim.
    [varIndices,~,~,isColonVars,~,t.varDim] = ...
        t.subs2inds(idxOp(1).Indices{2},'varDim',subsType);
    
    % Delete rows across all variables
    if isColonVars
        if isColonRows
            % subs2inds saw ':' and left t.rowDim alone, thinking it was t(:,varIndices) = [].
            % But it's t(:,:) = [], which should behave like t(1:n,:) = [], so remove all
            % rows as if it had been that.
            t.rowDim = t.rowDim.deleteFrom(rowIndices);
        end
        
        % Numeric indices and row labels can specify repeated LHS vars (logical and : can't).
        % Row labels have been translated to numeric indices, now remove any repeats.
        if isnumeric(rowIndices)
            rowIndices = unique(rowIndices);
            numRowIndices = length(rowIndices);
        end
        newNrows = t_nrowsExisting - numRowIndices;
        t_data = t.data; t.data = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
        for j = 1:t_nvarsExisting
            var_j = t_data{j}; t_data{j} = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
            if isa(var_j,'tabular')
                % Since we are in a try-catch block, need to put the assignment
                % expression in a local function to avoid unnecessary data
                % copies.
                var_j = localDelete(move(var_j),rowIndices);
            elseif ismatrix(var_j)
                % Directly do var_j(rowIndices,:) = []; without using reshape,
                % since it may not have one.
                var_j(rowIndices,:) = [];
            else
                sizeOut = size(var_j); sizeOut(1) = newNrows;
                var_j(rowIndices,:) = [];
                var_j = reshape(var_j,sizeOut);
            end
            t_data{j} = var_j;
        end
        t.data = t_data;
        
    % Delete entire variables
    elseif isColonRows
        varIndices = unique(varIndices); % subs2inds converts all types of var subscripts to numeric
        t.data(varIndices) = [];
      
    else
        error(message('MATLAB:table:InvalidEmptyAssignment'));
    end
catch ME
    throw(ME);
end

function var = localDelete(var,rowInds)
% Helper to do the deletion from var. This is mainly needed to avoid
% unnecesary data copies when doing the deletion inside a try-catch.
var(rowInds,:) = [];
