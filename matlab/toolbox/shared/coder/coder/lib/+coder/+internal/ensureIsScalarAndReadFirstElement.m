function out = ensureIsScalarAndReadFirstElement(cond)
%MATLAB Code Generation Private Function

%   Copyright 2020 The MathWorks, Inc.

%#codegen

coder.internal.errorIf(~isscalar(cond), ...
    'Coder:builtins:ConditionMustBeScalarLogical');
out = cond(1);
