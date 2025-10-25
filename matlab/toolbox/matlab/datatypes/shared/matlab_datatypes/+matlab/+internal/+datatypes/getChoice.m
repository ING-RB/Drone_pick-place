function [choiceNum,standardizedMatch] = getChoice(input,choices,choiceNums,priority,errorID)
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
%   CHOICENUM = GETCHOICE(INPUT,CHOICES,CHOICENUMS,PRIORITY,ERRORID) resolves ambiguous
%   partial matches in favor of the one with higher priority. PRIORITY can be used for
%   backwards compatibility when a new choice is added that creates the potential for a
%   partial match against multiple choices. In that case, set PRIORITY to 1 for the
%   existing choice, and to 0 for the new choice. GETCHOICE will resolve a partial match
%   in favor of the existing choice, preserving behavior of existing code that relied on
%   partial matching. When adding two new parameters that create a partial match ambiguity
%   among themselves, best practice would be to require a caller to specify parameter
%   names unambiguously.
%
%   PRIORITY should be the same length as CHOICES and CHOICENUMS. Situations requiring
%   both aliases (i.e. CHOICENUMS has repeated values) and priorities can be tricky, see
%   the example below.
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
%
% Examples:
%
%     A backwards compatibility case, where new choices 'next-or-current' and
%     'next-skip-current' were added, but the old choice 'next' must still work,
%     and is equivalent to the new choice 'next-or-current' and also shares a
%     partial match with 'nearest'. And there are aliases 'nextorcurrent' and
%     'nextskipcurrent' for the new choices.
%
%     import matlab.internal.datatypes.getChoice
%     msgID = 'MATLAB:datetime:dateshift:InvalidRule';
%     choices = {'nearest' 'next' 'next-or-current' 'nextorcurrent' 'next-skip-current' 'nextskipcurrent'};
%     choiceNums = [1 2 2 2 3 3];
%     choicePriorities = [1 1 0 0 0 0];
%     getChoice('ne',choices,choiceNums,choicePriorities,msgID) % error, ambiguous
%     getChoice('nearest',choices,choiceNums,choicePriorities,msgID) % returns 1
%     getChoice('next',choices,choiceNums,choicePriorities,msgID) % returns 2
%     getChoice('next-',choices,choiceNums,choicePriorities,msgID) % error, ambiguous
%     getChoice('next-or-current',choices,choiceNums,choicePriorities,msgID) % returns 2
%     getChoice('next-skip-current',choices,choiceNums,choicePriorities,msgID) % returns 3
%     getChoice('nextorcurrent',choices,choiceNums,choicePriorities,msgID) % returns 2
%     getChoice('nextskipcurrent',choices,choiceNums,choicePriorities,msgID) % returns 3

%
% See also PARTIALMATCH.

%   Copyright 2014-2021 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText

if nargin < 4
    errorID = choiceNums;
elseif nargin < 5
    errorID = priority;
end

if ~isScalarText(input,false) % weed out '', "", or <missing>
    % Non-text or non-scalar/empty text value. This always throws the error ID
    % specified in the required lat input.
    errorIDs = convertCharsToStrings(errorID);
    error(message(errorIDs(1)));
end

isMatch = strncmpi(input,choices,strlength(input));
if nargin == 3 % getChoice(input,choices,errorID)
    choiceNum = find(isMatch);
else % getChoice(input,choices,choiceNums,errorID) or getChoice(input,choices,choiceNums,priority,errorID)
    choiceNum = choiceNums(isMatch);
end

if isscalar(choiceNum)
    % OK, unambiguous match
elseif ~isempty(choiceNum) && all(choiceNum == choiceNum(1))
    % Match to multiple aliases of the same choice
    choiceNum = choiceNum(1);
else
    errorIDs = convertCharsToStrings(errorID);
    if isempty(choiceNum) % text, but no match
        if length(errorIDs) < 3
            % getChoice(...,ID_NOTTEXT_NOMATCH)
            % getChoice(...,[ID_NOTTEXT_NOMATCH ID_AMBIGUOUS])
            throwAsCaller(MException(message(errorIDs(1))));
        else % length(errorIDs) == 3
            % getChoice(...,[ID_NOTTEXT ID_NOMATCH ID_AMBIGUOUS])
            throwAsCaller(MException(message(errorIDs(2),input)));
        end
    else % matches multiple unaliased choices
        if nargin == 5
            matchPriority = priority(isMatch);
            maxPriority = max(matchPriority);
            if sum(matchPriority == maxPriority) == 1
                % One of the partial matches has the unique highest priority,
                % solving the ambiguity. Remove the other partial matches.
                choiceNum = choiceNum(matchPriority == maxPriority);
            end
        end
        if ~isscalar(choiceNum)
            % Multiple matches all have the highest priority, throw an error
            if length(errorIDs) == 1
                % getChoice(...,ID_NOTTEXT_NOMATCH)
                throwAsCaller(MException(message('MATLAB:datatypes:AmbiguousChoice',input)));
            else
                % getChoice(...,[ID_NOTTEXT_NOMATCH ID_AMBIGUOUS])
                % getChoice(...,[ID_NOTTEXT ID_NOMATCH ID_AMBIGUOUS])
                throwAsCaller(MException(message(errorIDs(end),input)));
            end
        end
    end
end
if nargout > 1
    if iscell(choices)
        standardizedMatch = choices{choiceNum};
    else
        standardizedMatch = choices(choiceNum);
    end
end
