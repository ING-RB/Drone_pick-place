function value = subsrefParens(this,s)
%

%SUBSREFPARENS Subscripted reference for a datetime.

% Normally, only multi-level paren references like d(i).Property get here (via
% subsref), and simple paren references go to parenReference. However, someone
% (including tabular) can call subsref explicitly, and this handles both.

%   Copyright 2014-2024 The MathWorks, Inc.

if ~isstruct(s), s = substruct('()',s); end

value = this;
value.data = this.data(s(1).subs{:});
if ~isscalar(s)
    switch s(2).type
    case '.'
        value = subsrefDot(value,s(2:end));
    case {'()' '{}'}
        error(message('MATLAB:datetime:InvalidSubscriptExpr'));
    end
end
