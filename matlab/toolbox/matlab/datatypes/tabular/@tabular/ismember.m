function [lia,locb] = ismember(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if nargin > 2
    narginchk(2,4);
    varargin = tabular.processSetMembershipFlags(varargin{:});
    % Anything left after removing rows is an error.
    if ~isempty(varargin)
        error(message('MATLAB:table:setmembership:UnknownFlag2',varargin{1}));
    end
end

[ainds,binds] = table.table2midx(a,b);

% Calling ismember with 'R2012a' gives occurrence='first'
[lia,locb] = ismember(ainds,binds,'rows','R2012a');
