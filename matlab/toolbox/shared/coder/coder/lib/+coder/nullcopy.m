function A = nullcopy(A)
%CODER.NULLCOPY creates uninitialized memory in generated code
%
%   X = CODER.NULLCOPY(A) copies the class, size, and all other
%   attributes of A to X.  In generated code, it does not copy element
%   values.
% 
%   Note: CODER.NULLCOPY produces uninitialized memory.  You are
%   responsible for initializing memory before it is read or passed
%   to another function. Failing to do so is dangerous and may lead 
%   to unpredictable behavior, including crashes, wrong answer or
%   uncompilable code. 
%
%   Please read the documentation before using this function. 
%
%   It is recommended that CODER.NULLCOPY only be used when undesirable
%   initialization is observed in the generated code.
%
%   CODER.NULLCOPY can only be used immediately on the right-hand side
%   of a complete assignment.
%
%   This is a code generation function.  In MATLAB, CODER.NULLCOPY(A)
%   returns A.
% 
%   Example:
%
%     % CODER.NULLCOPY prevents the initialization of X with zeros.
%     N = 5;
%     X = coder.nullcopy(zeros(1,N));
%     for i = 1:N
%        if mod(i,2) == 0
%           X(i) = i;
%        else
%           X(i) = 0;
%        end
%     end

%   Copyright 2008-2019 The MathWorks, Inc.
