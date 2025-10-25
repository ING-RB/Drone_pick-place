function [str, isUniquePartialMatch] = partialMatch(str, validStrs)
% STR = PARTIALMATCH(STR,VALIDSTRS) Returns the unique element of cellstr
% VALIDSTRS that is partial-matched by text scalar STR (case insensitive).
% If STR is not a unique partial-match of a string in VALIDSTRS, STR is
% returned unchanged.
%
% [STR,ISUNIQUEPARTIALMATCH] = PARTIALMATCH(STR,VALIDSTRS) returns logical
% scalar ISUNIQUEPARTIALMATCH indicating whether or not STR partial-matches
% one and only one value in VALIDSTRS.
%
% Use PARTIALMATCH to avoid erroring when STR does not partial-match any
% element of VALIDSTRS. If erroring for an invalid partial-match is the
% desired behavior, consider using GETCHOICE.
%
% See also GETCHOICE.

%   Copyright 2020 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isText

% We need to remove any non-scalar strings from validStrs, otherwise
% startsWith will error.
validStrs = validStrs(arrayfun(@(v) isScalarText(v,false) || isscalar(v) && isText(v,false),validStrs));
isUniquePartialMatch = false;
if isScalarText(str,false)
    matchIdx = startsWith(validStrs,str,'IgnoreCase',true);
    if nnz(matchIdx) == 1
        str = validStrs{matchIdx};
        isUniquePartialMatch = true;
    else
        isUniquePartialMatch = false;
    end
end
