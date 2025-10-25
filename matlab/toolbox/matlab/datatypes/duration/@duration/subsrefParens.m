function that = subsrefParens(this,s)
%

%SUBSREFPARENS Subscripted reference for a duration.

%   Copyright 2014-2024 The MathWorks, Inc.

% Normally, only multi-level paren references like d(i).Property get here (via
% subsref), and simple paren references go to parenReference. However, someone
% (including tabular) can call subsref explicitly, and this handles both.

if ~isstruct(s), s = substruct('()',s); end

that = this;
that.millis = this.millis(s(1).subs{:});
if ~isscalar(s)
    switch s(2).type
    case '.'
        that = subsrefDot(that,s(2:end));
    case {'()' '{}'}
        error(message('MATLAB:duration:InvalidSubscriptExpr'));
    end
end
