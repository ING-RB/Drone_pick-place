function p = isPermutation(perm, n)
%MATLAB Code Generation Private Function

%   isPermutation(perm) Returns true if perm has all integer elements and the elements
%   1:numel(perm), false otherwise.

%   isPermutation(perm, n) Returns true if perm has all integer elements and the elements
%   1:n, false otherwise.

%   Copyright 2024 The MathWorks, Inc.
%#codegen

coder.internal.allowHalfInputs;
coder.internal.prefer_const(perm, n);

if nargin < 2
    n = numel(perm);
end

p = (numel(perm) == n);
if ~p 
    return
end

b = false(n,1);
for k = 1:n
    j = perm(k);
    if j < 1 || j > n || coder.internal.scalar.floor(j) ~= j
        return
    end
    b(j) = true;
end
p = all(b);
