function p = isSizeEven(n)
%MATLAB Code Generation Private Function
%
%   Determines whether n is even, assuming n is a non-negative integer
%   value.
%
%   This is a small utility function that is written to generate just the
%   code needed to determine whether a size value is even. It does no error
%   checking. The output is indeterminate if n is not a non-negative
%   integer value.

%   Copyright 2019 The MathWorks, Inc.
%#codegen

coder.inline('always');
coder.internal.prefer_const(n);
p = ~coder.internal.lastBitOfSizeInt(n);
