function varargout = nonInlineCall(varargin)
% CODER.NONINLINECALL calls the specified function and prevents the 
% inlining of this function in the generated code. CODER.NONINLINECALL 
% overrides any CODER.INLINE directives in the body of the called function. 
% The specified function can have at most one output. To prevent the 
% inlining of a function with more than one output, specify the function 
% handle.
%
% CODER.NONINLINECALL does not prevent the inlining of empty functions
% and functions that return constant output.
%
% Examples:
%
% function x = foo(n) %#codegen
% x = coder.nonInlineCall(local_fun(n));
% end
% 
% function [x,y] = foo(n) %#codegen
% [x,y] = coder.nonInlineCall(@local_fun,n);
% end
%
% This code generation function has no effect in MATLAB.

%   Copyright 2023 The MathWorks, Inc.

[varargout{1:nargout}] = callOtherFunctionImpl(varargin{:});

