function A = cummax(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@cummax,true,varargin,true,"cummax",false);
