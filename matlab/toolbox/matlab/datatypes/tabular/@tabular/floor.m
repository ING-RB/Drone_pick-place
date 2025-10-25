function A = floor(A,varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.


A = tabular.unaryFunHelper(A,@floor,false,varargin,false,"floor",false);
