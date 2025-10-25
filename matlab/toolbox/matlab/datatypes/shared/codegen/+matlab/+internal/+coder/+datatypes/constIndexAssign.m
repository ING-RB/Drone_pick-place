function lhs = constIndexAssign(lhs, indices, rhs) %#codegen
%CONSTINDEXASSIGN Compile-time subscripted assignment utility.
%   LHS = CONSTINDEXASSIGN(LHS,INDICES,RHS) assigns RHS to the elements
%   of LHS specified by INDICES, at compile time. This is to work around
%   coder's limitation of not supporting "LHS(INDICES) = RHS" at compile
%   time.

%   Copyright 2020 The MathWorks, Inc.

assert(coder.internal.isConst(indices));     % INDICES must be constant for LHS to return as constant
assert(coder.internal.isConst(rhs));         % RHS must be constant for LHS to return as constant
assert(isequal(numel(indices), numel(rhs))); % INDICES & RHS must have same number of elements

% Due to coder limitation, simple index assignment is not compile-time:
%
%    lhs(indices) = rhs; % LHS cannot remain const with this expression
%
% Work around by assigning one element at a time in an explicitly unrolled loop
for i = coder.unroll(1:numel(rhs))
    lhs(indices(i)) = rhs(i);
end
coder.const(lhs);