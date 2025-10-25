function t = now()
%NOW    Current date and time as date number.
%   NOW is not recommended. Use datetime("now") instead.
%
%   T = NOW returns the current date and time as a serial date 
%   number.
%
%   FLOOR(NOW) is the current date and REM(NOW,1) is the current time.
%   DATESTR(NOW) is the current date and time as a character vector.
%
%   See also DATETIME.

%   Author(s): C.F. Garvin, 2-23-95
%   Copyright 1984-2022 The MathWorks, Inc.

% Clock representation of current time
t = datenum(clock);
