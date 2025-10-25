%EVAL Execute MATLAB expression in text.
%   EVAL(EXPRESSION) evaluates the MATLAB code in EXPRESSION. Specify
%   EXPRESSION as a character vector or string scalar.
%
%   [OUTPUT1,...,OUTPUTN] = EVAL(EXPRESSION) returns output from EXPRESSION
%   in the specified variables.
%
%   Security Considerations: When calling EVAL with untrusted user input,
%   validate the input to avoid unexpected code execution.
% 
%   Example: Interactively request the name of a matrix to plot.
%
%      expression = input('Enter the name of a matrix: ','s');
%      if (exist(expression,'var'))
%         plot(eval(expression))
%      end
%
%   See also FEVAL, EVALIN, ASSIGNIN, EVALC.

%   Copyright 1984-2020 The MathWorks, Inc.
%   Built-in function.
