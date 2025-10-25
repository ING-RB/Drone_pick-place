function this = subsasgn(this,s,rhs)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.lang.internal.move

try

    switch s(1).type
    case '()'
        % Normally, only creation and multi-level paren assignments like
        % d(i).Property = val come here, and simple paren assignments like
        % d(i) = val go directly to parenAssign. However, someone (including
        % tabular, for assignments like t.d(i) = val when d is a duration) can
        % call subsasgn explicitly.
        if isnumeric(this) && isequal(this,[]) % creating, RHS must have been a duration
            this = rhs;
            this.millis = [];
        end
        this = move(this).subsasgnParens(s,rhs);
    case '.'
        this = move(this).subsasgnDot(s,rhs);
    case '{}'
        error(message('MATLAB:duration:CellAssignmentNotAllowed'));
    end
    
catch ME
    throw(ME);
end
