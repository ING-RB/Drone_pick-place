function [pS,SampleTime] = maskInitializationFcnEKFPredictor(ProcessedMaskData)
%

%   Copyright 2017-2021 The MathWorks, Inc.

pS.FcnName = ProcessedMaskData.StateTransitionFcn.Name;
pS.IsSimulinkFcn = ProcessedMaskData.StateTransitionFcn.IsSimulinkFcn;
pS.NumberOfExtraArgumentInports = ProcessedMaskData.StateTransitionFcn.NumberOfExtraArgumentInports;

pS.JacobianFcnName = ProcessedMaskData.StateTransitionJacobianFcn.Name;
% JacobianFcn shares IsSimulinkFcn and NumberOfExtraArgumentInports with
% Fcn

pS.HasJacobian = ProcessedMaskData.HasJacobian.StateTransitionFcn;
pS.HasAdditiveNoise = ProcessedMaskData.HasAdditiveNoise.StateTransitionFcn;
SampleTime = ProcessedMaskData.SampleTimes.StateTransitionFcn;

% Determine if process noise covariance is time-varying
pS.HasTimeVaryingQ = ProcessedMaskData.HasTimeVaryingProcessNoise;
end
