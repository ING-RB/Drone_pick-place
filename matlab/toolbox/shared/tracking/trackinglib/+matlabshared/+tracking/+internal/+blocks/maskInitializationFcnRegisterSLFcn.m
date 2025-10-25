function [dataTypeID,SLFcnsToRegister] = ...
    maskInitializationFcnRegisterSLFcn(ProcessedMaskData, p)
%

%   Copyright 2017 The MathWorks, Inc.

% Data type
dataTypeID = matlabshared.tracking.internal.blocks.getSSDataType(ProcessedMaskData.DataType);

SLFcnsToRegister = {};
if p.IsSimulinkFcn
    % * This single flag is used for both Fcn and its Jacobian in EKF,
    % because we enforce them to be of the same type.
    % * In UKF and PF there is only one function (a state transition or
    % a measurement fcn, no Jacobians)
    
    % Simulink Fcns
    SLFcnsToRegister = {p.FcnName};
    % If this is EKF, also register the Jacobian Fcn (if it exists)
    if isfield(p,'HasJacobian') && p.HasJacobian
        SLFcnsToRegister{2} = p.JacobianFcnName;
    end
end