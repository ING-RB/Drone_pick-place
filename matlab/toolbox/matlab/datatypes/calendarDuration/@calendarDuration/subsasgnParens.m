function this = subsasgnParens(this,s,rhs)
%

%SUBSASGNPARENS Subscripted assignment to a calendarDuration.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.lang.internal.move

if ~isstruct(s), s = substruct('()',s); end

if ~isscalar(s)
    switch s(2).type
    case '.'
        name = s(2).subs;
        if name == "Format"
            % Setting the per-array properties via indexed assignment to a
            % subarray is not allowed.
            error(message('MATLAB:calendarDuration:SubArrayPropertyAssignment',name));
        end
        % An indexed assignment like d(i).Property = val can only be to a
        % per-array property (already caught as an error just above) or to a
        % per-element property (of which calendarDuration, unlike datetime, has
        % none). The calls to subsrefParens and subsasgnDot give the proper
        % error handling for the latter.
        subThis = subsrefParens(this,s(1));
        rhs = subsasgnDot(subThis,s(2:end),rhs);
    case {'()' '{}'}
        error(message('MATLAB:calendarDuration:InvalidSubscriptExpr'));
    end
    assert(false,'calDur(...).Name = val should be caught as an error in all cases.');
end

% Normally, only creation and multi-level paren assignments like
% d(i).Property = val come here (via subsasgn), and simple paren assignments
% like d(i) = val go directly to parenAssign. However, someone (including
% tabular, for assignments like t.d(i) = val when d is a calendarDuration) can
% call subsasgn explicitly. Higher subscripting levels have been removed above,
% hand off to parenAssign.
this = move(this).parenAssign(rhs,s.subs{:});
