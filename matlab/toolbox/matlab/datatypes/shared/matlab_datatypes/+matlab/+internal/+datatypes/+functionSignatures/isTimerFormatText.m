function tf = isTimerFormatText(txt)
% Check whether a text is in a timer format, such as '00:00:10', '8:0:0' etc.

%   Copyright 2018 The MathWorks, Inc.
timerFmtPattern = '^\d+:\d+:\d+:\d+$|^\d+:\d+:\d+$';
tf = isscalar(regexp(txt,timerFmtPattern));