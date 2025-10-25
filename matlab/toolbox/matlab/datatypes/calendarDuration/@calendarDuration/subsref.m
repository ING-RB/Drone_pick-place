function that = subsref(this,s)
%

%   Copyright 2014-2024 The MathWorks, Inc.

try

    switch s(1).type
    case '()'
        % Normally, only multi-level paren references like d(i).Property get here,
        % and simple paren references go to parenReference. However, someone
        % (including tabular) can call this method explicitly for the latter.
        that = subsrefParens(this,s);
    case '.'
        that = subsrefDot(this,s);
    case '{}'
        error(message('MATLAB:calendarDuration:CellReferenceNotAllowed'));
    end

catch ME
    throw(ME);
end
