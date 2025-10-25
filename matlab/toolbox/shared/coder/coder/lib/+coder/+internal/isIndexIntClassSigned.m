function p = isIndexIntClassSigned
%MATLAB Code Generation Private Function
%
%   Returns true if coder.internal.indexIntClass is a signed type.

%   Copyright 2006-2019 The MathWorks, Inc.
%#codegen

p = coder.const(coder.internal.indexInt(-1) < 0);
