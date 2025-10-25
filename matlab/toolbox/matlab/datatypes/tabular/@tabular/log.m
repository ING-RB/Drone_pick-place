function A = log(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@log,false,varargin);
