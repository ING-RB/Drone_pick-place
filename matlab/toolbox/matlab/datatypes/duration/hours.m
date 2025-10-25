function h = hours(x) %#codegen
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
   % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputHours',...
        'Correction',{'ReplaceIdentifierCorrection','hours','hour'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputTime',...
        'Correction',{'ReplaceIdentifierCorrection','hours','time'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double before scaling to avoid integer saturation, etc.
h = duration.fromMillis(3600*1000*full(double(x)),'h');

