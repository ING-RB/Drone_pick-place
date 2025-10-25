function b = sum(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

b = tabular.reductionFunHelper(a,@sum,varargin);
