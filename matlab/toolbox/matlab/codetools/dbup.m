%DBUP Shift current workspace to workspace of caller, while in debug mode
%   The DBUP command changes the current workspace context to the workspace 
%   of the calling function or script in the debug mode.
%
%   DBUP N changes the current workspace context to the workspace of the
%   calling function or script that is N levels higher on the call stack. 
%   Running DBUP N is equivalent to running the DBUP command N times.
%
%   See also DBDOWN, DBSTACK, DBSTEP, DBSTOP, DBCONT, DBCLEAR, 
%            DBTYPE, DBQUIT, DBSTATUS.

%   Copyright 1984-2019 The MathWorks, Inc.
%   Built-in function.

