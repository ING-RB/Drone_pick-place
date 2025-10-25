%WAIT Wait for Futures to complete
%    WAIT(F) blocks execution until each element of the array of Futures F has
%    reached the 'finished' state.
%
%    WAIT(F,STATE) blocks execution until each element of the array of
%    Futures F has reached the state STATE.
%
%    OK = WAIT(F,STATE,TIMEOUT) blocks execution for a maximum of TIMEOUT
%    seconds. OK is FALSE if TIMEOUT is exceeded before STATE is reached.
%
%    See also parfeval, parfevalOnAll, parallel.Future.cancel.

% Copyright 2013-2021 The MathWorks, Inc.
