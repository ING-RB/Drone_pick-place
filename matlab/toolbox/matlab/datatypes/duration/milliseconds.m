function s = milliseconds(x) %#codegen
%

%   Copyright 2015-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
    % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputSeconds',...
        'Correction',{'ReplaceIdentifierCorrection','milliseconds','second'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputTime',...
        'Correction',{'ReplaceIdentifierCorrection','milliseconds','time'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double
s = duration.fromMillis(full(double(x)),'s');
