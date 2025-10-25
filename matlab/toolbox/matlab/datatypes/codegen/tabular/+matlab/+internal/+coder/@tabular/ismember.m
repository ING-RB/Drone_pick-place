function [lia,locb] = ismember(a,b,varargin) %#codegen
%ISMEMBER Find rows in one table that occur in another table.

%   Copyright 2019 The MathWorks, Inc.

if nargin > 2
    narginchk(2,4);
    processedArgs = tabular.processSetMembershipFlags(varargin{:});
    % Anything left after removing rows is an error.
    if ~isempty(processedArgs)
        coder.internal.assert(false, 'MATLAB:table:setmembership:UnknownFlag2', processedArgs{1});
    end
end

[ainds,binds] = table.table2midx(a,b);

% Calling ismember with 'R2012a' gives occurrence='first'
[lia,locb] = ismember(ainds,binds,'rows','R2012a');
