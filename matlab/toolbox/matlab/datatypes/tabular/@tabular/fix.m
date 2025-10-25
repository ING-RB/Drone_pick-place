function A = fix(A,varargin)
%

% Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@fix,false,varargin,false,"fix",false);
