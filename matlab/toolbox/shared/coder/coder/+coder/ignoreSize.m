function y = ignoreSize(y)
%CODER.IGNORESIZE prevents function specialization on input size.
%
%   CODER.IGNORESIZE(expr) returns the value of expr at run time, 
%   but code generation cannot use the size of that value
%   to create a function specialization.
%
%   Example:
%
%       x = myfcn(n, coder.ignoreSize(1:10));
%       y = myfcn(n, coder.ignoreSize(1:5));
%       ...
%
%       function y = myfcn(x)
%           y = x + 1;
%       end
%
%   In the generated code, there will be only one specialization of myfcn.
%   
%   This is a code generation function. In MATLAB, CODER.IGNORESIZE(A) 
%   returns A.

%   Copyright 2018-2020 The MathWorks, Inc.
