function A = cumsum(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.


A = tabular.unaryFunHelper(A,@cumsum,true,varargin,true,"cumsum",false);
