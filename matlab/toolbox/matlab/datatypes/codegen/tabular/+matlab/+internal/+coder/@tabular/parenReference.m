function b = parenReference(t,varargin) %#codegen
%PARENREFERENCE parens subscripted reference for a table.

% This function is for internal use only and will change in a
% future release.  Do not use this function.

%   Copyright 2018-2022 The MathWorks, Inc.

subsType = matlab.internal.coder.tabular.private.tabularDimension.subsType;

coder.internal.errorIf(numel(varargin) == 1, 'MATLAB:table:LinearSubscript');
coder.internal.assert(numel(varargin) == t.metaDim.length, 'MATLAB:table:NDSubscript'); % Error for ND indexing

% Create an empty output table.
b = t.cloneAsEmpty(); % respect the subclass

% Translate row labels into indices (leaves logical and ':' alone).
t_rowDim = t.rowDim;
[rowIndices,~,~,isColonRows,~,b_rowDim] = t_rowDim.subs2inds(varargin{1},subsType.reference);
b.rowDim = b_rowDim;

% Translate variable (column) names into indices (translates logical and ':').
t_varDim = t.varDim;
[varIndices,~,~,~,~,b_varDim] = t_varDim.subs2inds(varargin{2},subsType.reference,t.data);

b.varDim = b_varDim;
numVarIndices = numel(varIndices);

% Move the data to the output.
b_data = coder.nullcopy(cell(1, numVarIndices));
t_data = t.data;
for j = 1:numVarIndices
    var_j = t_data{varIndices(j)};
    if isColonRows
        b_data{j} = var_j; % a fast shared-data copy
    elseif isa(var_j,'matlab.internal.coder.tabular')
        b_data{j} = parenReference(var_j, rowIndices, ':'); % force dispatch to overloaded table subscripting
    elseif ismatrix(var_j)
        if iscell(var_j)
            if islogical(rowIndices)
                numericRowIndices = find(rowIndices);
            else
                numericRowIndices = rowIndices;
            end
            % make a local copy within this if block, so that coder can decide
            % whether to make var_j_local homogeneous or heterogeneous
            var_j_local = var_j;
            % If we have an empty 0xM table, var_j would be an empty cell array.
            % Hence, the indexing logic below would result in an error because, 
            % coder would think that we are using a non-empty value to index 
            % into an empty cell array. To avoid this, if var_j is empty, we will 
            % return b1 as it is and error at runtime if the index turns out to
            % be non-empty.
            if coder.internal.isConst(size(var_j)) && isempty(var_j)
                coder.internal.assert(isempty(numericRowIndices),'MATLAB:table:RowIndexOutOfRange');
                b_data{j} = var_j_local;
            else
                b_dataj = coder.nullcopy(cell(numel(numericRowIndices), size(var_j,2)));
                isConstNumRows = coder.internal.isConst(numel(numericRowIndices));
                for k = 1:size(b_dataj,2)
                    coder.unroll(isConstNumRows);
                    for i = 1:size(b_dataj,1)
                        b_dataj{i, k} = var_j_local{numericRowIndices(i), k};
                    end
                end
                b_data{j} = b_dataj;
            end
        else
            b_data{j} = var_j(rowIndices,:); % without using reshape, may not have one
        end
    else
        % Each var could have any number of dims, no way of knowing,
        % except how many rows they have. Use selectRows to handle this case
        % appropriately.
        b_data{j} = matlab.internal.coder.tabular.selectRows(var_j,rowIndices);
    end
end
b.data = b_data;


% Create subscripters for the output. If the RHS subscripts are labels or numeric
% indices, they may have picked out the same row or variable more than once, but
% selectFrom creates the output labels correctly.
b.metaDim = t.metaDim;

% Move the per-array properties to the output.
b.arrayProps = t.arrayProps;
