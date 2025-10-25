function [L,U,support] = validateKDESupport(errPrefix, support, xmin, xmax, d)
%VALIDATEKDESUPPORT Validate that the given support/bounds align with the data for kde.
%   [L, U] = VALIDATEKDESUPPORT(ERRPREFIX, SUPPORT, XMIN, XMAX, D)
%   validates that the data support (valid range for it to live in)
%   specified in SUPPORT is the proper type. It can be one of 'unbounded',
%   'none', 'positive', 'nonnegative' or 'negative', or a vector/2xD matrix 
%   of specific exclusive bounds. It verifies that the data live within the
%   given bounds using double/single vectors XMIN, XMAX, where the data
%   have dimension D. ERRPREFIX is the prefix to use when throwing errors.
%   L and U are the validated bounds, and if SUPPORT was a named range, are
%   the numeric values corresponding to that range.
%
%   [L, U, SUPPORT] = VALIDATEKDESUPPORT(__) returns the given support
%   value. If it is a named option, it is returned as an exact match to one
%   of the named options (e.g., 'NEGATIVE' is returned as 'negative').
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.
support = convertStringsToChars(support);
if isnumeric(support)
    if d==1
        if numel(support)~=2
            throwError(errPrefix, 'SupportMustBeTwoElements')
        end
        L = support(1);
        U = support(2);
    else
        if size(support,1)~=2 || size(support,2)~=d
            % Can only ever hit this branch if user has SMLT, which will
            % come with this error message
            error(message('stats:mvksdensity:BadSupport',d));
        end
        L = support(1,:);
        U = support(2,:);
    end
    if any(L >= U)
        % Bound order swapped
        throwError(errPrefix, 'BoundsOutOfOrder');
    elseif any(L>=xmin) || any(U<=xmax)
        throwError(errPrefix, 'DataOutOfSupportRange');
    end
elseif ischar(support) && ~isempty(support)
    okvals = {'unbounded', 'positive', 'nonnegative', 'negative'};
    support = validatestring(support, okvals, '', 'Support');
    switch support
        case {'unbounded', 'none'}
            L = -Inf(1,d,"like",xmin);
            U = Inf(1,d,"like",xmax);
        case 'positive'
            L = zeros(1,d,"like",xmin);
            U = Inf(1,d,"like",xmax);
            if any(xmin <= 0)
                throwError(errPrefix, 'DataNotPositive');
            end
        case 'nonnegative'
            L = zeros(1,d,"like",xmin)-eps(zeros(1,1,'like', xmin));
            U = Inf(1,d,"like",xmax);
            if any(xmin < 0)
                throwError(errPrefix, 'DataNotNonnegative');
            end
        case 'negative'
            L = -Inf(1,d,"like",xmin);
            U = zeros(1,d,"like",xmax);
            if any(xmax >= 0)
                throwError(errPrefix, 'DataNotNegative');
            end
    end
else
    throwError(errPrefix, 'UnsupportedSupportType');
end
end

function throwError(errPrefix, errID, varargin)
% Helper to throw an error with a specific prefix and ID
throwAsCaller(MException(message([errPrefix, errID], varargin{:})));
end