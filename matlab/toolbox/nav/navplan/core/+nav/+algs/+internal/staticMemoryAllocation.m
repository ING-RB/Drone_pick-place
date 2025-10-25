function tf = staticMemoryAllocation()
% This function is for internal use only. It may be removed in the future.

%staticMemoryAllocation Checks if coder does static memory
%allocation

%   Copyright 2023 The MathWorks, Inc.

%#codegen

tf = ~coder.target("MATLAB") &&...
     ~coder.const(coder.internal.eml_option_eq('UseMalloc','VariableSizeArrays'));
