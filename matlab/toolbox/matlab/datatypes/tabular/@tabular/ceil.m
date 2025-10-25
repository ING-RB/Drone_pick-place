function A = ceil(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.


A = tabular.unaryFunHelper(A,@ceil,false,varargin,false,"ceil",false);
