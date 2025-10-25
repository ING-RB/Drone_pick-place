function [c,ia,ib] = intersect(a,b,varargin) %#codegen
%INTERSECT Find rows common to two tables.

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
    [sorted_binds, sorted_ib] = sortrows(binds);
    
    [~,ia,ib] = intersect(sorted_ainds,sorted_binds,flag,'rows');
    
    % Map the indices back to their values in the original unsorted inputs,
    % before doing further processing.
    ia = sorted_ia(ia);
    ib = sorted_ib(ib);
else
    [~,ia,ib] = intersect(ainds,binds,flag,'rows');
end

c = parenReference(a,ia,':');

% Use b's per-row, per-var, and per-array property values where a's were empty.
if ~a.rowDim.hasLabels && b.rowDim.hasLabels
    rowLabels = matlab.internal.coder.datatypes.cellstr_parenReference(b.rowDim.labels,ib);
    c_rowDim = c.rowDim.createLike(length(ib));
    c_rowDim = c_rowDim.setLabels(rowLabels,[],length(ib));
else
    c_rowDim = c.rowDim;
end

% First clone varDim to ensure properties, like VariableDescription, are varsized
c_varDim = clone(a.varDim);
c_varDim = c_varDim.mergeProps(b.varDim);
c_arrayProps = tabular.mergeArrayProps(a.arrayProps,b.arrayProps);
c = c.updateTabularProperties(c_varDim, [], c_rowDim, c_arrayProps);