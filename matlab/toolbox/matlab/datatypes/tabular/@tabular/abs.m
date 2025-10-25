function A = abs(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

A = tabular.unaryFunHelper(A,@abs,false,varargin,false,"abs",false);
