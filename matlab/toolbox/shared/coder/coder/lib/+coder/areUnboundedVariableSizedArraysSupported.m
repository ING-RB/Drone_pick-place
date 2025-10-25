function b = areUnboundedVariableSizedArraysSupported()
%CODER.AREUNBOUNDEDVARIABLESIZEDARRAYSSUPPORTED determines if unbounded
% variable-size arrays are supported during code generation or Simulink
% model simulation.
%
%   During code generation from MATLAB code, checks the states of code
%   configuration settings EnableDynamicMemoryAllocation and 
%   EnableVariableSizing. If both settings are enabled, returns true. 
%   Otherwise returns false.
%
%   During simulation of Simulink models, returns the state of the model
%   configuration setting MATLABDynamicMemAlloc.
% 
%   During code generation from Simulink models, checks the states of model
%   configuration settings MATLABDynamicMemAlloc and 
%   SupportVariableSizeSignals. If both settings are enabled, returns true. 
%   Otherwise returns false.
% 
%   In MATLAB execution, always returns true.
%
%   Example:
%     b = coder.areUnboundedVariableSizedArraysSupported;
%
%   Copyright 2023 The MathWorks, Inc.
%#codegen
coder.inline('always');
if coder.target('MATLAB')
    b = true;
    return;
end
b = coder.internal.eml_option_eq('UseMalloc', 'VariableSizeArrays') && coder.internal.eml_option_eq('VariableSizing', 'Enable');
