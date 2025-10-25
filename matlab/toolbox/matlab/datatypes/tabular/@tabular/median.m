function b = median(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

b = tabular.reductionFunHelper(a,@median,varargin);
