function this = subsasgn(this,s,rhs)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.lang.internal.move

% Make sure nothing follows the () subscript.
if ~isscalar(s)
    error(message('MATLAB:categorical:InvalidSubscripting'));
end

creating = isnumeric(this) && isequal(this,[]);
if creating % subscripted assignment to an array that doesn't exist
    this = rhs; % preserve the subclass
    this.codes = zeros(0,class(rhs.codes)); % account for the number of categories in b
end

switch s.type
case '()'
    % Categorical has no properties, and therefore no multi-level paren
    % assignments, so normally only creation comes here, and simple paren
    % assignments like d(i) = val go directly to parenAssign. However, someone
    % (including tabular, for assignments like t.d(i) = val when d is a
    % categorical) can call subsasgn explicitly. Hand off to parenAssign.
    this = move(this).parenAssign(rhs,s.subs{:});
case '{}'
    error(message('MATLAB:categorical:CellAssignmentNotAllowed'))
case '.'
    error(message('MATLAB:categorical:FieldAssignmentNotAllowed'))
end
