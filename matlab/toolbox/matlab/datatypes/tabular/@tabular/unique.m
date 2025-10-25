function [c,ia,ic] = unique(a,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

ainds = tabular.table2midx(a);
if nargin > 1
    varargin = tabular.processSetMembershipFlags(varargin{:});
end
[~,ia,ic] = unique(ainds,'rows',varargin{:});
c = a(ia,:);
