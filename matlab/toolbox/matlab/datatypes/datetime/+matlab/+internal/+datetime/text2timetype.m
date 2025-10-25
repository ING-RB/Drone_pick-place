function dt = text2timetype(text,msgID,template)
%TEXT2TIMETYPE Convert text to duration or datetime.
%   D = TEXT2TIMETYPE(TEXT,MSGID) is a wrapper for the duration and datetime
%   constructors that converts the char row, cellstr, or string array TEXT to
%   either a duration array or a datetime array. If TEXT cannot be converted,
%   TEXT2TIMETYPE throws the error specified by MSGID. MSGID must refer to a
%   message with exactly one hole for the unrecognizable text, e.g.
%   MATLAB:datetime:InvalidTextInput.
%
%   TEXT2TIMETYPE accepts scalar text or an array of text. The datetime and
%   duration constructors succeed if there are any (*) non-empty, non-NaN/NaT,
%   non-Inf elements of TEXT whose format is recognizable to them (or if all
%   elements are Inf or NaT/NaN). If an element is recognized, any other
%   elements that cannot be converted using that format are set to NaT or NaN
%   (as are any leading empty elements). This leaves the question of which type
%   TEXT2TIMETYPE returns, i.e. which constructor it calls.
%
%   (*) The datetime c'tor only looks at the first non-empty non-NaN/NaT/Inf
%   element, but the duration c'tor looks at all elements.
%
%   When all the elements of TEXT are 'Inf' or '', TEXT2TIMETYPE returns
%   datetimes, unless a duration template is provided (see below). If TEXT is
%   empty, TEXT2TIMETYPE returns an empty datetime.
%
%   When TEXT contains non-empty, non-Inf timestamps, duration has precedence.
%   If at least one element of TEXT is recognizable as a non-empty, non-NaN/Inf
%   duration (or if all are 'NaN', but not 'NaT'), then TEXT2TIMETYPE treats all
%   elements as durations (and if unrecognizable as such, they become NaNs).
%   This is true even if the recognized element could be interpreted as a
%   datetime. For example, scalar text such as '00:00:00' that might be either
%   duration or datetime is always converted to duration. If the duration
%   constructor fails, TEXT2TIMETYPE moves on to try datetime.
%
%   D = TEXT2TIMETYPE(TEXT,MSGID,TEMPLATE) specifies a duration or datetime
%   array to use as a guide for interpreting the input text. However, TEMPLATE
%   does NOT control the type of the output D (with some edge case exceptions).
%   The precedence is always "duration first, datetime only if that fails", and
%   TEMPLATE only serves to provide a duration or datetime format which would
%   not otherwise be automatically recognized (and also to set the format/time
%   zone of D). For example, a duration TEMPLATE can be used to provide a
%   non-standard format such as mm:ss so that text can be correctly interpreted
%   as a duration. But even if TEMPLATE is a datetime, if TEXT2TIMETYPE returns
%   durations if the text is recognizable as a duration.
%
%   Edge case exceptions: scalar text such as 'Inf' or '' are interpreted as the
%   template's type, as are arrays of all 'Inf' or all ''. An empty input
%   returns an empty of the template's type.
%
%   Given the duration precedence rule, TEXT2TIMETYPE should not be used in
%   cases where one or the other type is known to be needed -- call the
%   appropriate constructor. And in cases where a caller has been given "timer"
%   text for an input that can be either type, TEXT2TIMETYPE will always return
%   a duration, even though the text would be recognized by the datetime
%   constructor.

%   Copyright 2017-2019 The MathWorks, Inc.

import matlab.internal.datetime.isLiteralNonFinite

if ischar(text), text = string(text); end

hasTemplate = (nargin==3);
if hasTemplate
    assert(isa(template,'datetime') || isa(template,'duration'), 'Optional template must be a timetype');
end

% If the input array of timestamps is empty (as opposed to an array of empty
% timestamps), and a template is supplied, return an empty of the template type,
% with the same format and time zone (if datetime). If no template is supplied,
% return a datetime.
if isempty(text)
    if hasTemplate
        dt = template(zeros(size(text))); % preserve Format and TimeZone
    else
        dt = datetime.empty(size(text)); % for historic reasons
    end
    return
end

% Strip leading and trailing spaces, and get the text lengths.
text = strip(text);

% If all the timestamps are 'Inf' or zero-length, there's no information in the
% text to make a choice between duration and datetime. If a template is
% supplied, convert to the template's type. If no template is supplied, convert
% to datetime.
isLiteralInfOrEmpty = isLiteralNonFinite(text,"Inf",true); % include ''
if all(isLiteralInfOrEmpty)
    if hasTemplate
        if isduration(template)
            dt = duration(text,'Format',template.Format);
        else
            if hasDefaultFormat(template)
                % If the template is using the default format, don't force the equivalent
                % explicit format on the result, leave as default.
                dt = datetime(text,'Timezone',template.TimeZone);
            else
                dt = datetime(text,'Format',template.Format,'Timezone',template.TimeZone);
            end
        end
    else
        dt = datetime(text); % for historic reasons
    end
    return
end

% At this point, we have at least one non-empty non-Inf timestamp. Try to
% interpret them as durations first. If all of the timestamps are recognizable
% as durations return those durations.
try
    if hasTemplate && isduration(template)
        % Suggest the template's format to interpret the text, and create durations with
        % that format.
        dt = duration(text,'Format',template.Format);
    else
        % If no template is supplied, or if the template is a datetime, try to
        % guess the format, and create as durations with default format.
        dt = duration(text);
    end
    % At least one element was successfully recognized as a finite duration or
    % all elements were 'NaN', or all 'Inf'/'NaN' (all 'Inf' already caught).
    return
    % Otherwise, the only successes were (at best) 'Inf'/'NaN', but there are
    % also things not recognizable as durations.
catch
    % Did not find a recognizable finite duration.
end
% Unsuccessful with duration. move on to try to interpret the timestamps as
% datetimes.

try
    if hasTemplate && isdatetime(template)
        if hasDefaultFormat(template)
            % If the template is using the default format, don't force the equivalent
            % explicit format on the result, leave as default.
            dt = datetime(text,'Timezone',template.TimeZone);
        else
            % Otherwise suggest the template's format to interpret the text, and create
            % datetimes with that format and time zone.
            dt = datetime(text,'Format',template.Format,'Timezone',template.TimeZone);
        end
    else
        % If no template is supplied, or if the template is a duration, try to
        % guess the format, and create as unzoned datetimes with default format.
        dt = datetime(text);
    end
    % At least one element was successfully recognized as a finite datetime
    % or all elements were 'NaT', or all 'Inf'/'NaT' (all 'Inf' already caught).
    return
    % Otherwise, the only successes were (at best) 'Inf'/'NaT', but there are
    % also things not recognizable as datetimes.
catch
    % Did not find a recognizable finite datetime.
end

% At this point, there must have been some unrecognizable junk, but no elements
% recognizable as finite datetimes or durations (if there were, then the junk
% would have been tolerated by duration or datetime parsing). If there was only
% junk, or junk plus some recognized non-finites, that's an error. (Actually,
% datetime only looks at the first element that's not a literal non-finite, but
% to get here, that first one must have been junk.)
if iscell(text) || isstring(text)
    % Find the first unrecognized (complete junk) text for the error msg. 
    [tf,isLiteralNaN,isLiteralNaT] = isLiteralNonFinite(text,["NaN" "NaT" "Inf"],true); % include ''
    badOne = find(~tf,1,'first'); % empty input array already weeded out
    if isempty(badOne)
        % If there was no "complete junk" text, there must have been a mix of
        % literal NaN/NaT. The one encountered first would be recognizable and
        % would determine the time type, but the other one would then be
        % unrecognizable. Show the latter in the error msg.
        badOne = max([find(isLiteralNaN,1,'first'),find(isLiteralNaT,1,'first')]);
    end
    text = text{badOne};
end
error(message(msgID, text));
