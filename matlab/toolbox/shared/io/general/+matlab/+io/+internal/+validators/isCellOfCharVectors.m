function tf = isCellOfCharVectors(x)
%isCellOfCharVectors  True for a cell array of character vectors.
%   This function returns true if x is a cell vector containing only
%   row character arrays and false otherwise.

%   Copyright 2016-2018 The MathWorks, Inc.

tf = iscell(x) && ( isvector(x) || isequal(x, {}) );

if ~tf
    return
end

for i = 1:numel(x)
    if ~(ischar(x{i}) && (isrow(x{i}) || strcmp(x{i},'')))
        tf = false;
        return
    end
end
end
