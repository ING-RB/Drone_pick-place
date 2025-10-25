function [match, isUniquePartialMatch] = partialMatch(str, validStrs) %#codegen
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

%   Copyright 2020-2023 The MathWorks, Inc.
coder.internal.prefer_const(str,validStrs);
coder.extrinsic('matlab.internal.datatypes.partialMatch');

if coder.internal.isConst(str) && coder.internal.isConst(validStrs)
    [match,isUniquePartialMatch] = coder.const(@matlab.internal.datatypes.partialMatch,str,validStrs);
    return
end

% Requiring validStrs to be a cellstr simplifies the implementation because
% the output type for match is assumed to be char unless match can be
% determined at compile-time, removing the need to avoid a type mismatch in
% codegen.
coder.internal.assert(iscellstr(validStrs),'MATLAB:datatypes:MustBeCellstr'); %#ok<ISCLSTR>

% match (which must be the same type as defaultMatch) is assumed to have
% type char unless str is known to be an invalid type or size at
% compile-time.
isUniquePartialMatch = false;
if ~(isstring(str) || ischar(str)) % str is an invalid input type
    match = str;
    return
end

match = char(str);
if matlab.internal.coder.datatypes.isScalarText(str,false)
    validStrsTmp = validStrs;
    coder.varsize('validStrsTmp',[],false(size(validStrs)));
    for i = coder.internal.indexInt(1:coder.const(length(validStrs)))
        % Even though we force validStrs to be a cellstr, it's still possible that
        % validStrs{i} is not a scalar string (e.g. char matrix), in which case
        % startsWith would error.
        if matlab.internal.coder.datatypes.isScalarText(validStrsTmp{i},false) && startsWith(validStrsTmp{i},str,'IgnoreCase',true)
            if ~isUniquePartialMatch
                match = validStrsTmp{i};
                isUniquePartialMatch = true;
            else
                % str is a partial-match for multiple strings in validStrs
                match = char(str);
                isUniquePartialMatch = false;
                break
            end
        end
    end
end
