function tf = couldBeDatetimeText(txt)
% Check whether a text can be interpreted as a datetime by timerange

%   Copyright 2018-2020 The MathWorks, Inc.
uotChoices = matlab.internal.datatypes.functionSignatures.unitOfTimeChoices('yqmwdhms_plural');
tf = ~any(strncmp(txt,uotChoices,strlength(txt))) && ... % not a unitOfTime
     ~matlab.internal.datatypes.functionSignatures.isTimerFormatText(txt); % not a timer formatted text