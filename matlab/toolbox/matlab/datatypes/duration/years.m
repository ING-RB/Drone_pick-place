function y = years(x) %#codegen
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 1
    x = 1;
elseif (isnumeric(x) && isreal(x)) || islogical(x)
    % OK
elseif isa(x,'datetime')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:DatetimeInputYears',...
        'Correction',{'ReplaceIdentifierCorrection','years','year'});
elseif isa(x,'calendarDuration')
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:CalendarDurationInputYears',...
        'Correction',{'ReplaceIdentifierCorrection','years','calyears'});
else
    matlab.internal.datatypes.throwInMatlabOrCodegen('MATLAB:duration:InvalidDurationData');
end
% Convert any numeric to double before scaling to avoid integer saturation, etc.
y = duration.fromMillis(365.2425*86400*1000*full(double(x)),'y');
