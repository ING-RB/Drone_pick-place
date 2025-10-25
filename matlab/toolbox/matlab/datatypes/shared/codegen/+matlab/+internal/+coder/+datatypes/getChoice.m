function [choiceNum,standardizedMatch] = getChoice(input,choices,choiceNums,errorID) %#codegen
%GETCHOICE Return the index of the input from a list of choices
%   CHOICENUM = GETCHOICE(INPUT,CHOICES,ERRORID) returns the integer location of
%   INPUT in the list of CHOICES. INPUT is a scalar string or a char row.
%   CHOICES is a string array or a cellstr. ERRORID specifies errors to throw
%   as described below.
%
%   CHOICENUM = GETCHOICE(INPUT,CHOICES,CHOICENUMS,ERRORID)
%   defines a partition CHOICES into sets of aliases for equivalent choices. For example,
%      getChoice(input,{'dog' 'cat' 'canine' 'felid'},[1 2 1 2])
%   returns 1 for both 'dog' and 'canine'.
%
%   [CHOICENUM,STANDARDIZEDMATCH] = GETCHOICE(__) returns the standardized
%   match CHOICES(CHOICENUM) (or CHOICES{CHOICENUM} if CHOICES is a cell)
%   in STANDARDIZEDMATCH.
%
%   When ERRORID is a scalar string or a char row vector, GETCHOICE throws
%   ERRORID if INPUT is not scalar text or does not match any element in
%   CHOICES, and throws MATLAB:datatypes:getChoice:AmbiguousChoice if INPUT is
%   an ambiguous match. For example,
%      getChoice(input,choices,ID_NOTTEXT_NOMATCH)
%   where ID_NOTTEXT_NOMATCH : "Date component must be the text 'a' or 'b'."
%   The message corresponding to ERRORID have no holes.
%
%   When ERRORID is a two-element string or cellstr array, GETCHOICE throws
%      ERRORID(1) if INPUT is not scalar text, or does not match any element in CHOICES
%      ERRORID(2) if INPUT is an ambiguous match
%   For example,
%      getChoice(input,choices,[ID_NOTTEXT_NOMATCH ID_AMBIGUOUS])
%   where ID_NOTTEXT_NOMATCH : "Date component must be the text 'a' or 'b'."
%               ID_AMBIGUOUS : "Ambiguous date component: ''{0}''."
%   The messages corresponding to ERRORID(1) and ERRORID(2) have no holes and
%   one hole, respectively.
%
%   When ERRORID is a three-element string or cellstr array, GETCHOICE throws
%      ERRORID(1) if INPUT is not scalar text
%      ERRORID(2) if INPUT is scalar text but does not match any element in CHOICES
%      ERRORID(3) if INPUT is an ambiguous match
%   For example,
%      getChoice(input,choices,[ID_NOTTEXT ID_NOMATCH ID_AMBIGUOUS])
%   where   ID_NOTTEXT : "Date component must be the text 'a' or 'b'."
%           ID_NOMATCH : "Unrecognized date component: ''{0}''. Input must be 'a' or 'b."
%         ID_AMBIGUOUS : "Ambiguous date component: ''{0}''."
%   The messages corresponding to ERRORID(1), ERRORID(2), and ERRORID(3) have no
%   holes, one hole, and one hole, respectively.
%
% Use GETCHOICE if the desired behavior is to error when INPUT does not
% partial-match any element of CHOICES. If the desired behavior is NOT to
% error, consider using PARTIALMATCH.
%
% See also PARTIALMATCH.

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin < 4, errorID = choiceNums; end
if ischar(errorID)
    errorIDs = {errorID};
else
    errorIDs = errorID;
end
% weed out '', "", or <missing>
coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(input,false), errorIDs{1});

threeInputsProvided = nargin == 3;
choiceNum = 0;
for i = 1:numel(choices)
    if strncmpi(input,choices{i},strlength(input))
        if threeInputsProvided
            choiceNumOfMatch = i;
        else
            choiceNumOfMatch = choiceNums(i);
        end
        noMatchesFoundYet = choiceNum == 0;
        if noMatchesFoundYet
            choiceNum = choiceNumOfMatch;
        else
            choicesNotAliasedToSameChoice = choiceNumOfMatch ~= choiceNum;
            if choicesNotAliasedToSameChoice % OK if match to multiple aliases of the same choice
                % matches multiple unaliased choices
                oneErrorProvided = numel(errorIDs) == 1;
                % getChoice(...,ID_NOTTEXT_NOMATCH)
                coder.internal.errorIf(choicesNotAliasedToSameChoice && oneErrorProvided, 'MATLAB:datatypes:AmbiguousChoice',input);
                % getChoice(...,[ID_NOTTEXT_NOMATCH ID_AMBIGUOUS])
                % getChoice(...,[ID_NOTTEXT ID_NOMATCH ID_AMBIGUOUS])
                if coder.internal.isConst(input)
                    coder.internal.errorIf(choicesNotAliasedToSameChoice && ~oneErrorProvided,errorIDs{end},input);
                else
                    coder.internal.errorIf(choicesNotAliasedToSameChoice && ~oneErrorProvided,errorIDs{1});
                end
            end
        end
    end
end

noMatchesFound = choiceNum == 0;
if noMatchesFound
    % text, but no match
    threeErrorsProvided = numel(errorIDs) == 3;
    % getChoice(...,ID_NOTTEXT_NOMATCH)
    % getChoice(...,[ID_NOTTEXT_NOMATCH ID_AMBIGUOUS])
    if ~threeErrorsProvided
        coder.internal.errorIf(noMatchesFound && ~threeErrorsProvided, errorIDs{1});
    else
        % getChoice(...,[ID_NOTTEXT ID_NOMATCH ID_AMBIGUOUS])
        coder.internal.errorIf(noMatchesFound && threeErrorsProvided, errorIDs{2}, input);
    end
end

if nargout > 1
    if coder.internal.isConst(choices) && ~coder.internal.isConst(choiceNum)
        % avoid non-constant indexing into heterogeneous cellstr
        choicesTmp = choices;
        coder.varsize('choicesTmp',[],false(1,ndims(choicesTmp)));
        standardizedMatch = choicesTmp{choiceNum};
    else
        standardizedMatch = choices{choiceNum};
    end
end
