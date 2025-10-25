function mustBeStringOrCharOrCell(value)
%

%   Copyright 2024 The MathWorks, Inc.

    if ~(((isstring(value) || iscellstr(value)) && isvector(value)) || ischar(value))
        % Todo: Replace error msg with msg id
        error('Value must be a string array, char array, or cell array of character vectors.');
    end
end
