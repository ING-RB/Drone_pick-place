function [b,idx] = sortrows(a,varargin) %#codegen
%SORTROWS Sort rows of a table.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(varargin);

[vars,varData,sortMode,nvStart] = sortrowsFlagChecks(false,a,varargin{:});
sortModeStrs = {'ascend','descend'};

% Sort on each index variable, last to first.  Since sort is stable, the
% result is as if they were sorted all together.
if isequal(vars,0) % fast special case for simple row labels cases
    rowLabels = varData{1};
    
    % If sorting by RowNames with no labels fast exit
    if (~a.rowDim.hasLabels)
        b = a;
        return
    end
    
    if iscell(rowLabels)
        if coder.internal.isConst(size(rowLabels))
            % Ensure rowLabels is homogeneous
            coder.varsize('rowLabels',[],[false false]);
        end
        % Error if additional NV pair arguments are supplied
        coder.internal.assert(nvStart == nargin,'MATLAB:table:sortrows:NVPairsCellstr');
        [~,idxTmp] = matlab.internal.coder.datatypes.cellstr_sort(rowLabels,sortModeStrs{sortMode});
        idx = double(idxTmp); % Ensure the output idx is double
    else
        [~,idx] = sort(rowLabels,sortModeStrs{sortMode},varargin{nvStart:end});
    end
else
    idx = (1:a.rowDimLength)';
    % Append the metaDim name to the list of labels. This is only used in error
    % messages.
    labels = coder.const(feval('horzcat',{a.metaDim.labels{1}},a.varDim.labels));
    coder.unroll();
    for j = length(vars):-1:1
        var_j = varData{j};
        coder.internal.assert(ismatrix(var_j),...
            'MATLAB:table:sortrows:NDVar',labels{vars(j)+1});
        % Error gracefully when trying to sort tables of tables
        coder.internal.assert(~isa(var_j,'tabular'),...
            'MATLAB:table:sortrows:SortOnVarFailed',labels{vars(j)+1},class(var_j));
        if iscellstr(var_j) %#ok<ISCLSTR>
            % Error if the cellstr variable is not a column vector.
            coder.internal.assert(iscolumn(var_j),'MATLAB:table:sortrows:MultiColumnCellstr',...
                'IfNotConst','Fail');
            % Error if additional NV pair arguments are supplied
            coder.internal.assert(nvStart == nargin,'MATLAB:table:sortrows:NVPairsCellstr');
            
            cellstr_var = matlab.internal.coder.datatypes.cellstr_parenReference(var_j,idx);
            [~,ord] = matlab.internal.coder.datatypes.cellstr_sort(cellstr_var,sortModeStrs{sortMode(j)});
        else
            if ~iscell(var_j)
                var = var_j(idx,:);
            else
                var = var_j;
                % Cell arrays will error later on, so no need to modify those
            end
            if ~iscell(var) && coder.internal.isConstTrue(iscolumn(var))
                
                [~,ord] = sort(var,1,sortModeStrs{sortMode(j)},varargin{nvStart:end});
            else % multi-column, or cell
                % Sort by all columns, all either ascending or descending
                cols = (1:size(var,2)) * 2*(1.5-sortMode(j));
                [~,ord] = sortrows(var,cols,varargin{nvStart:end});
            end
        end
        idx = idx(ord);
    end
end

b = parenReference(a,idx,':');
