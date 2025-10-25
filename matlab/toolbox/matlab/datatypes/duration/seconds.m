function s = seconds(x) %#codegen
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
    % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputSeconds',...
        'Correction',{'ReplaceIdentifierCorrection','seconds','second'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputTime',...
        'Correction',{'ReplaceIdentifierCorrection','seconds','time'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double before scaling to avoid integer saturation, etc.
s = duration.fromMillis(1000*full(double(x)),'s');
