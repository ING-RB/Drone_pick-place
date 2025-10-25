function [td,tdate] = timeofday(tt)
%TIMEOFDAY Elapsed time since midnight for tall array of datetimes.
%   D = TIMEOFDAY(T)
%   [D,DATE] = TIMEOFDAY(T)
%
%   See also DATETIME/TIMEOFDAY.

%   Copyright 2015-2021 The MathWorks, Inc.

if nargout < 2
    td = datetimePiece(mfilename, 'duration', tt);
else
    [td,tdate] = datetimePiece(mfilename, [], tt);
    td = setKnownType(td, 'duration');
    tdate = setKnownType(tdate, 'datetime');
end
