function [y, isUniqueElem] = constUnique(x) %#codegen
%CONSTUNIQUE Compile-time unique.
%   [Y,ISUNIQUEELEM] = CONSTUNIQUE(X) returns the unique values in the 
%   constant array, X, at compile time. Result is constant folded so runtime
%   does not scale with size. (WARNING: __consider__ compile time note below)
%
%   Compile/codegen time scales very sensitively to size. This utility is
%   well suited for small sized array from which _const_ unique values are
%   required (i.e. builtin unique is runtime and the result is not const)

%   Copyright 2020 The MathWorks, Inc.

% input must be compile-time constant
assert(coder.internal.isConst(x));
if numel(x) <= 1
    y = x; % already unique
else
    % mark duplicate elements
    isUniqueElem = true(size(x));
    for i = coder.unroll(1:numel(x))
        for ii = coder.unroll(1:i-1)
            if x(i) == x(ii)
                isUniqueElem(i) = false;
                break;
            end
        end
    end
    
    % delete duplicates -- do not use [] as that changes size
    y = coder.const(x(isUniqueElem));
end