function c = table2cell(t,varargin)  %#codegen
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    c = matlab.internal.coder.table2cell(t, varargin{:});
    return
end

if ~isa(t,'tabular')
    error(message('MATLAB:table2cell:NonTable'))
end

% Each variable in D becomes a single column in C.
[nrows,nvars] = size(t);
c = cell(nrows,nvars);

t_vars = getVars(t,false);
for j = 1:nvars
    vj = t_vars{j};
    if iscell(vj)
        if iscolumn(vj)
            % If the cell var is a single column, copy it into D as is.
            c(:,j) = vj;
        else
            % If the cell var is multi-column, break it apart by rows, but keep
            % each row intact.
            c(:,j) = mat2cell(vj,ones(nrows,1));
        end
    else
        % If the variable is not a cell array, split it up into cells, one per row.
        c(:,j) = mat2cell(vj,ones(nrows,1));
    end
end
