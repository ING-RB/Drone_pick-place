function [c,ia,ib] = intersect(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

% Calling intersect with either 'sorted' or 'stable' gives occurrence='first'
[~,ia,ib] = intersect(ainds,binds,flag,'rows');
c = a(ia,:);

% Get the labels from b if a doesn't have them.
if ~a.rowDim.hasLabels && b.rowDim.hasLabels
    % Since the labels are coming from a valid rowDim, no need to validate them.
    % Directly call assignLabels to skip validation.
    c.rowDim = c.rowDim.assignLabels(b.rowDim.labels(ib),true);
end

% Use b's per-row, per-var, and per-array property values where a's were empty.
c.rowDim = c.rowDim.mergeProps(b.rowDim);
c.varDim = a.varDim.mergeProps(b.varDim,1:b.varDim.length);
c.arrayProps = tabular.mergeArrayProps(a.arrayProps,b.arrayProps);
