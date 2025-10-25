function b = prod(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

b = tabular.reductionFunHelper(a,@prod,varargin,DropUnits=true);
