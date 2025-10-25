function tt2 = retime(tt1,newTimes,varargin)
%   TT2 = RETIME(TT1,NEWTIMES)
%   TT2 = RETIME(TT1,NEWTIMESTEP,METHOD)
%   TT2 = RETIME(TT1,NEWTIMES,METHOD) 
%   TT2 = RETIME(..., 'PARAM1',val1, 'PARAM2',val2, ...)
%
%   Limitations:
%   1) Interpolation methods 'spline' and 'makima' are not supported.
%   2) Name value pair 'EndValues' is not supported.
%   3) Retiming to 'regular' spaced row times is not supported.
%   4) All variables in input timetables must support missing values
%   (floating point, categorical, datetime, duration, or text) for the
%   methods 'nearest', 'next', and 'previous'.
%
%   See also TIMETABLE/RETIME, TIMETABLE/SYNCHRONIZE.

%   Copyright 2017-2021 The MathWorks, Inc.

invalidOpts = {'union', 'intersection', 'commonrange', 'first', 'last'};
if ~istall(newTimes) && any(strcmpi(newTimes, invalidOpts))
    error(message('MATLAB:timetable:synchronize:InvalidNewTimesForRetime'))
end
tt2 = synchronize(tt1,newTimes,varargin{:});
