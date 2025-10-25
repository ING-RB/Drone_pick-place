function that = subsref(this,s)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.tryThrowIllegalDotMethodError

% Make sure nothing follows the () subscript.
if ~isscalar(s)
    isDotParenReference = isequal({s.type},{'.','()'});
    if isDotParenReference
        name = s.subs;
        tryThrowIllegalDotMethodError(this,name,'MethodsWithNoCorrection',"cat");
        error(message('MATLAB:categorical:FieldReferenceNotAllowed'));
    else
        error(message('MATLAB:categorical:InvalidSubscripting'));
    end
end

switch s.type
case '()'
    % Normally, only multi-level paren references like c(i).Property get here,
    % and for categorical those are an error and caught above. Simple paren
    % references should normally go to parenReference. But someone (including
    % tabular) might call this method explicitly, so handle the latter.
    that = this.parenReference(s.subs{:});
case '{}'
    error(message('MATLAB:categorical:CellReferenceNotAllowed'))
case '.'
    name = s.subs;
    tryThrowIllegalDotMethodError(this,name,'MethodsWithNoCorrection',"cat");
    error(message('MATLAB:categorical:FieldReferenceNotAllowed'));
end
