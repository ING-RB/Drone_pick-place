function y = length(this)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.inline('always');
if this.m == ZERO || this.n == ZERO
    y = double(ZERO);
else
    y = double(max2(this.m,this.n));
end

%--------------------------------------------------------------------------
