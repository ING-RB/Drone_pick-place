function this = subsasgnParens(this,s,rhs)
%

%SUBSASGNDOT Subscripted assignment to a datetime.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.lang.internal.move

if ~isstruct(s), s = substruct('()',s); end

if ~isscalar(s)
    switch s(2).type
    case '.'
        name = s(2).subs;
        if matches(name,["Format" "TimeZone"])
            % Setting the per-array properties via indexed assignment to a
            % subarray is not allowed.
            error(message('MATLAB:datetime:SubArrayPropertyAssignment',name));
        end
        % Setting per-element properties of a subarray (e.g. dt(2).Month = 1) is
        % allowed. Get the subArray, set the properties, then reassign the subarray
        % back into the larger array as though it were the RHS.
        subThis = subsrefParens(this,s(1));
        rhs = subsasgnDot(subThis,s(2:end),rhs);
        s = s(1);
        % At this point, both this and rhs are datetimes.
    case {'()' '{}'}
        error(message('MATLAB:datetime:InvalidSubscriptExpr'));
    end
end

% Normally, only creation and multi-level paren assignments like
% d(i).Property = val come here (via subsasgn), and simple paren assignments
% like d(i) = val go directly to parenAssign. However, someone (including
% tabular, for assignments like t.d(i) = val when d is a datetime) can call
% subsasgn explicitly. Higher subscripting levels have been removed above, hand
% off to parenAssign.
this = move(this).parenAssign(rhs,s.subs{:});
