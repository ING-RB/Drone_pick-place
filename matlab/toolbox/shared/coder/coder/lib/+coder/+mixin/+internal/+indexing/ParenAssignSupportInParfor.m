classdef (Abstract, HandleCompatible) ParenAssignSupportInParfor
% Inhriting from thsi Coder-specific mixin indicates that this class supports 
% parenAssign inside PARFOR. 
%
% By default, these methods error out inside parfor body.
% Inheriting from this mixin overides that behavior.

%   Copyright 2024 The Math Works, Inc.
%#codegen
end
