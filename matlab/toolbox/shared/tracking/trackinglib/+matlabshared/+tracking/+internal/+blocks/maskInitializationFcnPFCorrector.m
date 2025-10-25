function [pM,pRegisterSLFcn,SampleTime] = maskInitializationFcnPFCorrector(blkH, ProcessedMaskData)
% Mask initialization code for the CorrectX blocks underneath the particle
% filter block. X is an integer >=1 representing which measurement function
% this is.
%
% Collect the relevant and necessary data from parent PF block's large data
% structure (ProcessedMaskData). These are utilized in two locations:
% * MATLAB Function block responsible for correction takes pM as a
% non-tunable parameter
% * If user has Simulink Functions, the SFcn responsible for registering
% the Simulink Function
%
% Inputs:
%    blkH              - Handle to the CorrectX block
%    ProcessedMaskData - Verified user data from the parent PF block mask

%   Copyright 2017 The MathWorks, Inc.

% Get the integer X, from the block name CorrectX
MeasurementId = matlabshared.tracking.internal.blocks.getCorrectBlockIndex(blkH);

pM.FcnName = ProcessedMaskData.MeasurementFcn.Name{MeasurementId};
pM.IsSimulinkFcn = ProcessedMaskData.MeasurementFcn.IsSimulinkFcn(MeasurementId);
pM.NumberOfExtraArgumentInports = ProcessedMaskData.MeasurementFcn.NumberOfExtraArgumentInports(MeasurementId);

pM.ResamplingMethod = ProcessedMaskData.ResamplingMethod;
pM.TriggerMethod = ProcessedMaskData.TriggerMethod;
pM.SamplingInterval = ProcessedMaskData.SamplingInterval;
pM.MinEffectiveParticleRatio = ProcessedMaskData.MinEffectiveParticleRatio;
pM.DataType = ProcessedMaskData.DataType;
pM.RandomNumberGenerator = ProcessedMaskData.RandomNumberGenerator;
pM.NumParticles = ProcessedMaskData.NumParticles;
pM.IsStateOrientationColumn = ProcessedMaskData.IsStateOrientationColumn;
% Ensure all correction operations have a different RNG seed
pM.Seed = ProcessedMaskData.Seed + MeasurementId;

% The following are used in C++ S-Fcn pfRegisterSimulinkFcnSFcn. Their data
% types must match with the S-Fcn source code
pRegisterSLFcn.IsStateOrientationColumn = logical(ProcessedMaskData.IsStateOrientationColumn);
pRegisterSLFcn.NumStates = int32(ProcessedMaskData.NumStates);
pRegisterSLFcn.NumParticles = int32(ProcessedMaskData.NumParticles);
% Make sure int32 casts did not change the values. processDialogDataPF
% has checks for this, but be safe.
assert(pRegisterSLFcn.NumStates == ProcessedMaskData.NumStates);
assert(pRegisterSLFcn.NumParticles == ProcessedMaskData.NumParticles);

SampleTime = ProcessedMaskData.SampleTimes.MeasurementFcn(MeasurementId);
end