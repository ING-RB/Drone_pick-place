% MaskInit code for the particle filter block. Package mask variables so
% that they can be processed easier by downstream functions.
%
% Having the script in a file here instead of the block directly
% allow easier debugging (can use breakpoints)

%   Copyright 2017-2022 The MathWorks, Inc.

matlabshared.tracking.internal.blocks.initializeFilter();

% StateTransitionFcn
dlgParams.FcnInfo.Predict.Fcn = {StateTransitionFcn};
dlgParams.FcnInfo.Predict.ExpectedNargin = 1;
dlgParams.StateTransitionFcnSampleTime = StateTransitionFcnSampleTime;
dlgParams.HasStateTransitionFcnExtraArgument = HasStateTransitionFcnExtraArgument;
% Initialization parameters
dlgParams.NumberOfParticles = NumberOfParticles;
dlgParams.InitialDistribution = InitialDistribution;
dlgParams.InitialMean = InitialMean;
dlgParams.InitialCovariance = InitialCovariance;
dlgParams.InitialStateBounds = InitialStateBounds;
dlgParams.Particles = InitialParticles;
dlgParams.Weights = InitialWeights;
dlgParams.CircularVariables = CircularVariables;
dlgParams.StateOrientation = StateOrientation;
% MeasurementFcns
dlgParams.FcnInfo.Correct.Fcn = cell(NumberOfMeasurements,1);
dlgParams.HasMeasurementEnablePort = false(NumberOfMeasurements,1);
dlgParams.MeasurementFcnSampleTime = cell(NumberOfMeasurements,1);
dlgParams.HasMeasurementFcnExtraArgument = false(NumberOfMeasurements,1);
for kk=1:NumberOfMeasurements
    % Functions
    dlgParams.FcnInfo.Correct.Fcn{kk} = eval( sprintf('MeasurementLikelihoodFcn%d',kk) );
    % Sample time
    dlgParams.MeasurementFcnSampleTime{kk} = eval( sprintf('MeasurementLikelihoodFcn%dSampleTime',kk) );
    % The rest
    dlgParams.HasMeasurementEnablePort(kk) = eval( sprintf('HasMeasurementEnablePort%d',kk) );
    dlgParams.HasMeasurementFcnExtraArgument(kk) = eval( sprintf('HasMeasurementFcnExtraArgument%d',kk) );
end
dlgParams.NumberOfMeasurements = NumberOfMeasurements;
dlgParams.FcnInfo.Correct.ExpectedNargin = 2*ones(dlgParams.NumberOfMeasurements,1);
% Resampling
dlgParams.ResamplingMethod = ResamplingMethod;
dlgParams.TriggerMethod = TriggerMethod;
dlgParams.MinEffectiveParticleRatio = MinEffectiveParticleRatio;
dlgParams.SamplingInterval = SamplingInterval;
dlgParams.Randomness = Randomness;
dlgParams.Seed = Seed;
% Settings
dlgParams.StateEstimationMethod = StateEstimationMethod;
dlgParams.OutputParticles = OutputParticles;
dlgParams.OutputWeights = OutputWeights;
dlgParams.OutputStateCovariance = OutputStateCovariance;
dlgParams.UseCurrentEstimator = UseCurrentEstimator;
dlgParams.EnableMultirate = EnableMultirate;
dlgParams.SampleTime = SampleTime;
dlgParams.DataType = DataType;
% Main MaskInit code
[p,signalCheck] = matlabshared.tracking.internal.blocks.maskInitializationFcnPF(gcbh,dlgParams);
clear dlgParams tempVar kk; % Avoid block from storing the struct in block's WS
