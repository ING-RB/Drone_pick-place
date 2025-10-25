function p = isCompiled
%MATLAB Code Generation Private Function

%   This definition is replaced during coverage testing.

%   Copyright 2016 The MathWorks, Inc.
%#codegen

coder.inline('always');
p = ~isempty(coder.target);