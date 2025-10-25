function c = table2cell(t,varargin)  %#codegen
%TABLE2CELL Convert table to cell array.

%   Copyright 2019-2020 The MathWorks, Inc.

% Each variable in D becomes a single column in C.
[nrows,nvars] = size(t);
% coder.nullcopy is necessary for some empty tables with zero variables,
% coder is unable to determine the number of rows and unable to verify all
% cells are populated
c = coder.nullcopy(cell(nrows,nvars));

t_vars = getVars(t,false);
% Only unroll if the table variables are heterogeneous, or if table 
% contains heterogeneous cell array variables
t_vars_homogeneous = coder.internal.isHomogeneousCell(t_vars) && ...
    (nvars == 0 || ~iscell(t_vars{1}) || coder.internal.isHomogeneousCell(t_vars{1})); 
coder.unroll(~t_vars_homogeneous)
for j = 1:nvars
    vj = t_vars{j};
    % determine the size of each row (may be N-D)
    vjrow_sz = size(vj);
    vjrow_sz(1) = 1;
    if iscell(vj)
        if iscolumn(vj)
            % If the cell var is a single column, copy it into D as is.
            %c(:,j) = vj;
            coder.unroll(~t_vars_homogeneous)
            for i = 1:nrows
                c{i,j} = vj{i};
            end
        else
            % If the cell var is multi-column, break it apart by rows, but keep
            % each row intact.
            %c(:,j) = mat2cell(vj,ones(nrows,1));
            coder.unroll(~t_vars_homogeneous)
            for i = 1:nrows
                c{i,j} = reshape({vj{i,:}}, vjrow_sz);
            end
        end
    else
        % If the variable is not a cell array, split it up into cells, one per row.
        %c(:,j) = mat2cell(vj,ones(nrows,1));
        coder.unroll(~t_vars_homogeneous)
        for i = 1:nrows
            c{i,j} = reshape(vj(i,:), vjrow_sz);
        end
    end
end