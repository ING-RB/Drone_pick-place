function m = minutes(x) %#codegen
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
    % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputMinutes',...
        'Correction',{'ReplaceIdentifierCorrection','minutes','minute'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputTime',...
            'Correction',{'ReplaceIdentifierCorrection','minutes','time'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double before scaling to avoid integer saturation, etc.
m = duration.fromMillis(60*1000*full(double(x)),'m');

