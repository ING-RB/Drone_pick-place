function d = days(x) %#codegen
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
    % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputDays',...
        'Correction',{'ReplaceIdentifierCorrection','days','day'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputDays',...
        'Correction',{'ReplaceIdentifierCorrection','days','caldays'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double before scaling to avoid integer saturation, etc.
d = duration.fromMillis(86400*1000*full(double(x)),'d');
