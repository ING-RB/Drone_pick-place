function [pM,SampleTime] = maskInitializationFcnEKFCorrector(blkH, ProcessedMaskData)
% Mask initialization code for the CorrectX blocks underneath the EKF
% block. X is an integer >=1 representing which measurement function this
% is.
%
% Collect the relevant and necessary data from parent EKF block's large 
% data structure (ProcessedMaskData). These are utilized in two locations:
% * MATLAB Function block responsible for correction takes pM as a
% non-tunable parameter
% * If user has Simulink Functions, the SFcn responsible for registering
% the Simulink Function
%
% Inputs:
%    blkH              - Handle to the CorrectX block 
%    ProcessedMaskData - Verified user data from the parent EKF block mask

%   Copyright 2017-2021 The MathWorks, Inc.

% Get the integer X, from the block name CorrectX
MeasurementId = matlabshared.tracking.internal.blocks.getCorrectBlockIndex(blkH);

pM.FcnName = ProcessedMaskData.MeasurementFcn.Name{MeasurementId};
pM.IsSimulinkFcn = ProcessedMaskData.MeasurementFcn.IsSimulinkFcn(MeasurementId);
pM.NumberOfExtraArgumentInports = ProcessedMaskData.MeasurementFcn.NumberOfExtraArgumentInports(MeasurementId);

pM.HasJacobian = ProcessedMaskData.HasJacobian.MeasurementFcn(MeasurementId);
pM.JacobianFcnName = ProcessedMaskData.MeasurementJacobianFcn.Name{MeasurementId};

pM.HasAdditiveNoise = ProcessedMaskData.HasAdditiveNoise.MeasurementFcn(MeasurementId);
SampleTime = ProcessedMaskData.SampleTimes.MeasurementFcn(MeasurementId);
pM.HasWrapping = ProcessedMaskData.HasWrapping(MeasurementId);

% Determine if respective measurement noise covariances are time-varying
pM.HasTimeVaryingR = ProcessedMaskData.HasTimeVaryingMeasurementNoise(MeasurementId);
end
