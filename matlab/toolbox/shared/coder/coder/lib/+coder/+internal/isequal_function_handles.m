function Result = isequal_function_handles(A, B)
%MATLAB Code Generation Private Function
%
% MATLAB implementation

%   Copyright 2014-2019 The MathWorks, Inc.
coder.internal.assert(isa(A, 'function_handle'), 'Coder:builtins:ExpectedFunctionHandle', class(A));
coder.internal.assert(isa(B, 'function_handle'), 'Coder:builtins:ExpectedFunctionHandle', class(B));
Result = isequal(A, B);
