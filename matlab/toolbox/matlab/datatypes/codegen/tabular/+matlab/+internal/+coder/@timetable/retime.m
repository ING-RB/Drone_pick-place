function tt2 = retime(tt1,newTimes,method,varargin)  %#codegen
%RETIME Adjust a timetable and its data to a new vector of row times.

%   Copyright 2020 The MathWorks, Inc.

% fend off 
coder.internal.errorIf(any(strncmpi(newTimes,{'union', 'intersection', 'commonrange', 'first', 'last'},1)), ...
    'MATLAB:timetable:synchronize:InvalidNewTimesForRetime');

if nargin == 2
    tt2 = synchronize(tt1,newTimes);
elseif nargin == 3
    tt2 = synchronize(tt1,newTimes,method);
else
    tt2 = synchronize(tt1,newTimes,method,varargin{:});
end
