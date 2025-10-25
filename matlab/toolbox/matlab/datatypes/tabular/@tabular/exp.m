function A = exp(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@exp,false,varargin);
