function dt = text2timetype(text,msgID,template) %#codegen
%   DT = TEXT2TIMETYPE(TEXT,MSGID) is a wrapper for the duration and datetime
%   constructors that converts the char row, cellstr, or string array TEXT to
%   either a duration array or a datetime array. If TEXT cannot be converted,
%   TEXT2TIMETYPE throws the error specified by MSGID. MSGID must refer to a
%   message with exactly one hole for the unrecognizable text, e.g.
%   MATLAB:datetime:InvalidTextInput.
%
%   duration is tried first, so text such as '00:00:00' that might be either
%   datetime or duration is converted to duration.
%
%   The datetime and duration constructors error if the format of the first
%   non-empty element of TEXT is not automatically recognizable. If that first
%   element can be converted, any subsequent elements that cannot be converted
%   using that format are set to NaT or NaN.

%   Copyright 2019 The MathWorks, Inc.

% Currently we do not allow using text to subscript into a timetable, will update the method once
% this is supported
coder.internal.assert(false,'MATLAB:timetable:InvalidRowSubscriptsDuration');