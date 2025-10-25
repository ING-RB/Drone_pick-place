function tt2 = retime(tt1,newTimes,method,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

% fend off 
if any(strncmpi(newTimes,["union", "intersection", "commonrange", "first", "last"],1))
    error(message('MATLAB:timetable:synchronize:InvalidNewTimesForRetime'))
end

try %#ok<ALIGN>
if nargin == 2
    tt2 = synchronize(tt1,newTimes);
elseif nargin == 3
    tt2 = synchronize(tt1,newTimes,method);
else
    tt2 = synchronize(tt1,newTimes,method,varargin{:});
end
catch ME, throw(ME); end % keep the stack trace to one level
