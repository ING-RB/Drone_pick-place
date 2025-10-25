function p = isCharOrScalarString(s)
%MATLAB Code Generation Private Function

% This file is for MATLAB execution only
%   Copyright 2016-2019 The MathWorks, Inc.

p = ischar(s) || (isstring(s) && isscalar(s));
