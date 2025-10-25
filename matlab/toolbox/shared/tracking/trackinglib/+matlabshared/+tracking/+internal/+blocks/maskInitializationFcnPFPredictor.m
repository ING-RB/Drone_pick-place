function [pS,SampleTime] = maskInitializationFcnPFPredictor(ProcessedMaskData)
% Mask initialization code for the Predict block underneath the particle
% filter block.
%
% Collect the relevant and necessary data from parent PF block's large data
% structure (ProcessedMaskData). These are utilized in two locations:
% * MATLAB Function block responsible for correction takes pS as a
% non-tunable parameter
% * If user has Simulink Functions, the SFcn responsible for registering
% the Simulink Function

%   Copyright 2017 The MathWorks, Inc.

pS.FcnName = ProcessedMaskData.StateTransitionFcn.Name;
pS.IsSimulinkFcn = ProcessedMaskData.StateTransitionFcn.IsSimulinkFcn;
pS.NumberOfExtraArgumentInports = ProcessedMaskData.StateTransitionFcn.NumberOfExtraArgumentInports;

pS.IsStateVariableCircular = ProcessedMaskData.IsStateVariableCircular;

% Following members of pM are used in C++ SFcn pfRegisterSimulinkFcnSFcn.
% Their data types must match with the SFcn source code
pS.IsStateOrientationColumn = int32(ProcessedMaskData.IsStateOrientationColumn);
pS.NumStates = int32(ProcessedMaskData.NumStates);
pS.NumParticles = int32(ProcessedMaskData.NumParticles);

SampleTime = ProcessedMaskData.SampleTimes.StateTransitionFcn;
end