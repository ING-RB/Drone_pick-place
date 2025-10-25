function varargout = const(varargin)
%CODER.CONST evaluates an expression or function call at compile time.
%
%   CODER.CONST(EXPR) evaluates expression EXPR. This can handle simple
%   function calls, e.g. A = coder.const(fcn(10)).
%
%   [A1,...,An] = CODER.CONST(@FCN, ARG1, ..., ARGn) calls function @FCN with
%   multiple output arguments.
%

%   Copyright 2013-2023 The MathWorks, Inc.

[varargout{1:nargout}] = callOtherFunctionImpl(varargin{:});