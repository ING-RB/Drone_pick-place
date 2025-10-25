function [c,ia] = setdiff(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

% Calling setdiff with either 'sorted' or 'stable' gives occurrence='first'
[~,ia] = setdiff(ainds,binds,flag,'rows');

c = a(ia,:);
