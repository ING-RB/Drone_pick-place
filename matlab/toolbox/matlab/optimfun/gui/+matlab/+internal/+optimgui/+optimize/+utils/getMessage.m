function msg = getMessage(catalogName, id)

% This function returns the catalog entry of message ids
%
% INPUTS:
%   catalogName (1, :) char - Name of an optim_gui catalog
%   id (1, :) char OR cell array of (1, :) char - Message id in catalog
%
% OUTPUTS:
%   msg (1, :) char OR cell array of (1, :) char - Corresponding catalog messages

% Copyright 2020-2023 The MathWorks, Inc.

switch class(id)
    
    % If passed a char id, return corresponding message
    case 'char'
        msg = getString(message(['MATLAB:optimfun_gui:', catalogName, ':', id]));
        
        % If passed a cell array of message ids, return a cell array of corresponding messages
    case 'cell'
        msg = cell(size(id));
        for count = 1:numel(id)
            msg{count} = getString(message(['MATLAB:optimfun_gui:', catalogName, ':', id{count}]));
        end
end
end
