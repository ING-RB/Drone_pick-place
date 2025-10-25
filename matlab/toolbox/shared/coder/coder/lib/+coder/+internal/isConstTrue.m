function x = isConstTrue(x)
%MATLAB Code Generation Private Function
%
%   Returns true if x is a compile-time constant evaluating to true or
%   running in MATLAB, otherwise returns false.
%
%   Note that coder.internal.isConstTrue(x) is not generally the same thing
%   as ~coder.internal.isConstFalse(x). When x is constant, they are the
%   same, but when x is not constant, coder.internal.isConstFalse(x) and
%   coder.internal.isConstTrue(x) both return false.

%   Copyright 2020-2024 The MathWorks, Inc.
%#codegen
arguments
    x (1,1) {mustBeA(x, 'logical')}
end
