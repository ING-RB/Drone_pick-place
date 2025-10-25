%DBDOWN Reverse workspace shift performed by DBUP, while in debug mode
%   The DBDOWN command is used in conjunction with the DBUP command to
%   change the workspace context when in the debug mode. The DBDOWN
%   command reverses the context shift performed by DBUP. 
%
%   DBDOWN N changes the current workspace context to the workspace of the
%   called function or script that is N levels lower on the call stack. 
%   Running DBDOWN N is equivalent to running the DBDOWN command N times.
%
%   See also DBSTEP, DBSTOP, DBCONT, DBCLEAR, DBTYPE, DBSTACK, DBUP,
%            DBSTATUS, DBQUIT.

%   Copyright 1984-2019 The MathWorks, Inc.
%   Built-in function.

