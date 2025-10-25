function [b,idx] = sortrows(a,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

[vars,varData,sortMode,varargin] = sortrowsFlagChecks(false,a,varargin{:});

% Sort on each index variable, last to first.  Since sort is stable, the
% result is as if they were sorted all together.
if isequal(vars,0) % fast special case for simple row labels cases
    rowLabels = varData{1};
    
    % If sorting by RowNames with no labels fast exit
    if (~a.rowDim.hasLabels)
        b = a;
        return
    end
    
    if sortMode == 1
        [~,idx] = sort(rowLabels,varargin{:});
    else % sortMode == 2
        if iscell(rowLabels)
            [~,idx] = sortrows(rowLabels,-1,varargin{:}); % cellstr does not support 'descend'.
        else
            [~,idx] = sort(rowLabels,'descend',varargin{:});
        end
    end
else
    sortModeStrs = {'ascend','descend'};
    idx = (1:a.rowDim.length)';
    for j = length(vars):-1:1
        var_j = varData{j};
        if ~ismatrix(var_j)
            error(message('MATLAB:table:sortrows:NDVar',a.varDim.labels{vars(j)}));
        elseif istabular(var_j)
            % Error gracefully when trying to sort tables of tables
            error(message('MATLAB:table:sortrows:SortOnVarFailed',a.varDim.labels{vars(j)},class(var_j)));
        end
        var_j = var_j(idx,:);
        % cell/sort is only for cellstr, use sortrows for cell always.
        if ~iscell(var_j) && isvector(var_j) && (size(var_j,2) == 1)
            try
                [~,ord] = sort(var_j,1,sortModeStrs{sortMode(j)},varargin{:});
            catch ME
                throw(addCause(...
                    MException(message('MATLAB:table:sortrows:SortOnVarFailed',a.varDim.labels{vars(j)},class(var_j))),...
                    ME));
            end
        else % multi-column, or cell
            % Sort by all columns, all either ascending or descending
            cols = (1:size(var_j,2)) * 2*(1.5-sortMode(j));
            try
                [~,ord] = sortrows(var_j,cols,varargin{:});
            catch ME
                throw(addCause(...
                    MException(message('MATLAB:table:sortrows:SortrowsOnVarFailed',a.varDim.labels{vars(j)},class(var_j))),...
                    ME));
            end
        end
        idx = idx(ord);
    end
end

b = a(idx,:);
