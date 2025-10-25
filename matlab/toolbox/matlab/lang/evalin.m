%EVALIN Evaluate expression in workspace.
%   EVALIN(WS,'expression') evaluates 'expression' in the context of
%   the workspace WS.  WS can be 'caller' or 'base'.  It is similar to EVAL
%   except that you can control which workspace the expression is
%   evaluated in.
%
%   [X,Y,Z,...] = EVALIN(WS,'expression') returns output arguments from
%   the expression.
%
%   Security Considerations: When calling EVALIN with untrusted user input,
%   validate the input to avoid unexpected code execution.
% 
%   See also EVAL, ASSIGNIN.

%   Copyright 1984-2020 The MathWorks, Inc.

%   Built-in function
