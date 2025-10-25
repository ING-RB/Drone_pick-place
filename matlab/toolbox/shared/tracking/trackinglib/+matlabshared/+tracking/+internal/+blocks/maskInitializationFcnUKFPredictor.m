function [pS,SampleTime] = maskInitializationFcnUKFPredictor(ProcessedMaskData)
%

%   Copyright 2017-2021 The MathWorks, Inc.

pS.FcnName = ProcessedMaskData.StateTransitionFcn.Name;
pS.IsSimulinkFcn = ProcessedMaskData.StateTransitionFcn.IsSimulinkFcn;
pS.NumberOfExtraArgumentInports = ProcessedMaskData.StateTransitionFcn.NumberOfExtraArgumentInports;

pS.HasAdditiveNoise = ProcessedMaskData.HasAdditiveNoise.StateTransitionFcn;
pS.Alpha = ProcessedMaskData.Alpha;
pS.Beta = ProcessedMaskData.Beta;
pS.Kappa = ProcessedMaskData.Kappa;
SampleTime = ProcessedMaskData.SampleTimes.StateTransitionFcn;

% Determine if process noise covariance is time-varying
pS.HasTimeVaryingQ = ProcessedMaskData.HasTimeVaryingProcessNoise;
end
