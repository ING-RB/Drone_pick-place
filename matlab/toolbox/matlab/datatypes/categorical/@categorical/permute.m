function b = permute(a,order)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

b = a;
% Call the built-in to ensure correct dispatching regardless of what's in order
b.codes = builtin('permute',a.codes,order);
