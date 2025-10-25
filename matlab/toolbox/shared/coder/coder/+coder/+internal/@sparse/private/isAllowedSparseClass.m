function p = isAllowedSparseClass(s)
%MATLAB Code Generation Private Function

%   Copyright 2017-2024 The MathWorks, Inc.
%#codegen
coder.inline('always');
% s is a variable, check that it has the expected class
p = coder.internal.sparse.isAllowedSparseClass(s, true);