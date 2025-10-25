function [c,ia] = setdiff(a,b,varargin) %#codegen
%SETDIFF Find rows that occur in one table but not in another.

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

if flag == "sorted"
    % Sort the multi-index matrices, so that the rows are in ascending order, as
    % this is required by core set membership functions
    [sorted_ainds, sorted_ia] = sortrows(ainds);
    sorted_binds = sortrows(binds);
    
    [~,idx] = setdiff(sorted_ainds,sorted_binds,'sorted','rows');
    
    % Map the indices back to their values in the original unsorted inputs,
    % before doing further processing.
    ia = sorted_ia(idx);
else
    % Otherwise directly call the core functions
    [~,ia] = setdiff(ainds,binds,flag,'rows');
end

c =  parenReference(a,ia,':');
