%NARGIN Number of function input arguments.
%   Inside the body of a user-defined function, NARGIN returns the number
%   of input arguments that were used to call the function. If the function
%   uses an arguments validation block, then only positional arguments
%   provided by the function call are included in this number. Optional
%   arguments not provided by the caller are not included. Name-value
%   arguments are never included, whether provided or not.
%
%   NARGIN(FUN) returns the number of declared inputs for the
%   function FUN. The number of arguments is negative if the function has a
%   variable number of input arguments. If the function uses an arguments
%   validation block, NARGIN returns the number of declared positional
%   arguments on the function line as a nonnegative value. FUN can be a
%   function handle that maps to a specific function, or a character vector
%   or string scalar that contains the name of that function.
%
%   See also NARGOUT, VARARGIN, NARGINCHK, INPUTNAME, MFILENAME.

%   Copyright 1984-2019 The MathWorks, Inc.
%   Built-in function.



