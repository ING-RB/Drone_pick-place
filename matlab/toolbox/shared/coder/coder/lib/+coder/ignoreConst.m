function A = ignoreConst(A)
%CODER.IGNORECONST prevents function specialization due to constant inputs
%
%   CODER.IGNORECONST(expr) returns the value of expr at run time, 
%   but if the value is a constant, code generation cannot use that value 
%   to create a function specialization.
%
%   Example:
%
%       x = myfcn(n, coder.ignoreConst('mode1'));
%       y = myfcn(n, coder.ignoreConst('mode2'));
%       ...
%
%       function y = myfcn(n,mode)
%           if strcmp(mode,'mode1')
%               y = n;
%           else
%               y = -n;
%       end
%
%   In the generated code, there will be only one specialization of myfcn.
%   
%   For some recursive function calls, you can use coder.ignoreConst to 
%   force run-time recursion.
%
%   Note: CODER.IGNORECONST(A) does not prevent constant folding of A in 
%   general. It only prevents function specialization based on the constant 
%   value of A.
%
%   This is a code generation function. In MATLAB, CODER.IGNORECONST(A) 
%   returns A.

%   Copyright 2019 The MathWorks, Inc.
