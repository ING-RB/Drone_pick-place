function A = cumprod(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.


A = tabular.unaryFunHelper(A,@cumprod,true,varargin,true);
