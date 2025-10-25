function name = makeUserReadableName(s)
%MATLAB Code Generation Private Function

%   Copyright 2018 The MathWorks, Inc.

% Compute the char vector to use for the readable class name of a sparse matrix
%#codegen
if coder.target('MATLAB')
    name = 'sparse matrix';
else
    name = coder.internal.sparseUserReadableName(s);
end
