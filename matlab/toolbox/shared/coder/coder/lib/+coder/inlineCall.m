function varargout = inlineCall(varargin)
% CODER.INLINECALL calls and inlines the specified function in the 
% generated code. CODER.INLINECALL overrides any CODER.INLINE directives in 
% the body of the called function. The specified function can have at most 
% one output. To inline a function with more than one output, specify the 
% function handle.
%
% CODER.INLINECALL does not support the inlining of recursive functions,
% functions that contain parfor-loops, and functions called from 
% parfor-loops.
%
% Examples:
%
% function x = foo(n) %#codegen
% x = coder.inlineCall(local_fun(n));
% end
% 
% function [x,y] = foo(n) %#codegen
% [x,y] = coder.inlineCall(@local_fun,n);
% end
%
% This code generation function has no effect in MATLAB.

%   Copyright 2023 The MathWorks, Inc.

[varargout{1:nargout}] = callOtherFunctionImpl(varargin{:});

