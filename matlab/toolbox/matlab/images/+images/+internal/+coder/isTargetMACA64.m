function tf = isTargetMACA64() %#codegen
% tf = isTargetMACA64
% Return true if the generated code or this function is running on MACA64
% Machine

% Copyright 2022 The MathWorks, Inc.

arch = coder.const(feval('computer', 'arch'));
tf = strcmpi(arch,'MACA64');