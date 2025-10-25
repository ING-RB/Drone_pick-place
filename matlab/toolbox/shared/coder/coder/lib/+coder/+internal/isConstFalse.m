function y = isConstFalse(x)
%MATLAB Code Generation Private Function
%
%   Returns true if x is (compile-time constant or running in MATLAB)
%   and false, otherwise false. Nargin must be 1, and the input must be a scalar logical.
%
%   Note that coder.internal.isConstFalse(x) is not generally the same
%   thing as ~coder.internal.isConstTrue(x). When x is constant, they are
%   the same, but when x is not constant, coder.internal.isConstFalse(x)
%   and coder.internal.isConstTrue(x) both return false.

%   Copyright 2020-2023 The MathWorks, Inc.
arguments
    x (1,1) {mustBeA(x, 'logical')}
end
y = ~x;
