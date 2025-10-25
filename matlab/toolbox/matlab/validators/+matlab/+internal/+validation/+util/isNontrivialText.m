function tf = isNontrivialText(value)
% isNontrivialText Check input text has semantic significance.
%    Use isNonzeroLengthText when it is avaliable.
    
%   Copyright 2020-2024 The MathWorks, Inc.

    % istext
    % {} and string.empty are empty but not trivial text
    if ~(ischar(value) && (isrow(value) || isequal(value,''))) && ~isstring(value) && ~iscellstr(value)
        tf = false;
        return;
    end

    % has at least one character
    if ~all(strlength(value)>0, 'all')
        tf = false;
        return;
    end

    tf = true;
end
