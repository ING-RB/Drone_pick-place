function A = sin(A, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.


A = tabular.unaryFunHelper(A,@sin,false,varargin);
