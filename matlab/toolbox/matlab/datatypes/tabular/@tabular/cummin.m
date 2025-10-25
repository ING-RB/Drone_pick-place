function A = cummin(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@cummin,true,varargin,true,"cummin",false);
