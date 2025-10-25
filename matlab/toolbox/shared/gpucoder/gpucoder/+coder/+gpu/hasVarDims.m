function flag = hasVarDims(var)
%#codegen

%   Copyright 2017-2020 The MathWorks, Inc.

flag = ~coder.internal.isConst(size(var));
