function that = subsrefParens(this,s)
%

%SUBSREFPARENS Subscripted reference for a calendarDuration.

%   Copyright 2014-2024 The MathWorks, Inc.

% Normally, only multi-level paren references like d(i).Property get here (via
% subsref), and simple paren references go to parenReference. However, someone
% (including tabular) can call subsref explicitly, and this handles both.

if ~isstruct(s), s = substruct('()',s); end

that = this;
theComponents = that.components;

% If the array is not a scalar zero, at least one of the fields must not be a
% scalar zero placeholder, and will have subscripting applied. Any remaining
% (scalar zero placeholder) fields can be left alone. However, if the array is a
% scalar zero, have to handle the possibility of Tony's trick, or at least throw
% an error for out of range subscripts, so apply the subscripting to (arbitrarily)
% seconds.
nonZeros = false;
if ~isequal(theComponents.months,0)
    nonZeros = true;
    theComponents.months = theComponents.months(s(1).subs{:});
end
if ~isequal(theComponents.days,0)
    nonZeros = true;
    theComponents.days = theComponents.days(s(1).subs{:});
end
if ~isequal(theComponents.millis,0) || (nonZeros == false)
    theComponents.millis = theComponents.millis(s(1).subs{:});
end

that.components = theComponents;

if ~isscalar(s)
    switch s(2).type
    case '.'
        that = subsrefDot(that,s(2:end));
    case {'()' '{}'}
        error(message('MATLAB:calendarDuration:InvalidSubscriptExpr'));
    end
end
