function p = allowFloatingPointEqualityCheck
%MATLAB Code Generation Library Function

%   Copyright 2024 The MathWorks, Inc.
%#codegen

p = ~coder.const(@matlab.internal.feature,...
    "EMLDisAllowFloatingPointEqualityChecksInMathFcns");